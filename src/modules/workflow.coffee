fs = require 'fs-extra'
path = require 'path'

_ = require 'lodash'
walk = require 'walkdir'
async = require 'async'
tmp = require 'temporary'
shell = require 'shelljs'

splitter = require './splitter'
util = require '../utilities'

verbose = false
workflowLocation = ''
assetpress = {}
globalOptions = {}

performWorkflow = (workflowObject, cb) ->
  sourcePath = util.resolvePath workflowObject.source, workflowLocation
  if !fs.existsSync sourcePath
    process.stdout.write "Error: Source #{ sourcePath } does not exist.\n"
    return cb()

  if workflowObject.output
    if _.isString(workflowObject.output)
      outputObject = { destination: util.resolvePath(workflowObject.output, workflowLocation) }
    else
      if workflowObject.output.destination
        outputObject = workflowObject.output
        outputObject.destination = util.resolvePath(workflowObject.output.destination, workflowLocation)
      else
        process.stdout.write "Error: Output needs to be a string, an object with 'destination' key or nothing.\n"
        return cb()
  else
    suggestedDestination = util.resolvePath '../AssetPress Resources', sourcePath
    outputObject = { destination: suggestedDestination, suggestedDestination: true }

  temporaryDirectoryObject = new tmp.Dir
  temporaryDirectory = temporaryDirectoryObject.path
  temporaryDirectory = util.addTrailingSlash temporaryDirectory

  if fs.lstatSync(sourcePath).isDirectory()
    fs.copySync sourcePath, temporaryDirectory + 'source'
    outputObject.destination = util.resolvePath("../#{ path.basename(sourcePath) } Resources", sourcePath) if outputObject.suggestedDestination
  else
    sourceDetails = path.parse sourcePath
    if sourceDetails.ext.toLowerCase() is '.sketch'
      if shell.which('sketchtool')
        shellOutput = shell.exec("sketchtool export slices --output=#{ util.escapeShell(temporaryDirectory + 'source') } #{ util.escapeShell(sourcePath) }", { silent: !verbose })
        outputObject.destination = util.resolvePath("../#{ path.basename(sourcePath, '.sketch') } Resources", sourcePath) if outputObject.suggestedDestination
      else
        process.stdout.write "Error: Sketchtool is required. Download it from http://bohemiancoding.com/sketch/tool/\n"
        fs.removeSync temporaryDirectory
        return cb()
    else
      process.stdout.write "Error: AssetPress workflow currently only accepts directories and Sketch files as source.\n"
      fs.removeSync temporaryDirectory
      return cb()

  if workflowObject.screens and _.isString(workflowObject.screens)
    screensPath = util.resolvePath workflowObject.screens, workflowLocation
    splitter {
      source: temporaryDirectory + 'source'
      resourcesDestination: '.'
      screensDestination: screensPath
    }
    process.stdout.write "Splitted screens to #{ screensPath }\n" if verbose

  if workflowObject.assetpress and _.isObject(workflowObject.assetpress)
    assetPressOptions = workflowObject.assetpress
    unless assetPressOptions.os
      process.stdout.write "Warning: Running AssetPress with iOS implied. Please set 'os' value in assetpress object.\n"
      assetPressOptions.os = 'ios'
    assetPressOptions.inputDirectory = temporaryDirectory + 'source'
    assetPressOptions.outputDirectory = 'output'
    assetPressOptions.screensDirectory = false
    assetPressOptions.verbose = verbose
    assetPressOptions.complete = -> 
      process.stdout.write "Completed AssetPress for #{ sourcePath }\n" if verbose

      currentOutputDirectory = temporaryDirectory + 'output'
      if assetPressOptions.os is 'ios' and assetPressOptions.iosXcassets
        currentOutputDirectory += '.xcassets'
        if outputObject.suggestedDestination
          outputObject.destination = util.removeTrailingSlash(outputObject.destination) + '.xcassets'
        else
          if !_.endsWith( util.removeTrailingSlash(outputObject.destination), '.xcassets' )
            outputObject.destination = util.removeTrailingSlash(outputObject.destination) + '.xcassets'

      workflowMoveOutput(currentOutputDirectory, outputObject, workflowObject, temporaryDirectory, cb)

    assetpress assetPressOptions
  else
    unless outputObject.suggestedDestination
      workflowMoveOutput(temporaryDirectory + 'source', outputObject, workflowObject, temporaryDirectory, cb)
    else
      # Otherwise do nothing
      fs.removeSync temporaryDirectory
      cb()
    

workflowMoveOutput = (from, to, workflowObject, temporaryDirectory, cb) ->

  sourceSlash = util.addTrailingSlash(util.resolvePath(workflowObject.source, workflowLocation))
  destinationSlash = util.addTrailingSlash(to.destination)

  if destinationSlash.indexOf(sourceSlash) is 0
    process.stdout.write "Error: destination is inside source.\n"
    fs.removeSync temporaryDirectory
    return cb()

  fs.removeSync destinationSlash # MAYBE - would it be possible to have a non-clean export?
  fs.mkdirpSync path.resolve(destinationSlash, '..')
  fs.renameSync util.addTrailingSlash(from), destinationSlash
  fs.removeSync temporaryDirectory
  process.stdout.write "Moved output to #{ to.destination }\n" if verbose

  if to.git
    if to.gitRoot
      if shell.which('git')
        gitWorkTree = util.addTrailingSlash(to.gitRoot)
        gitDir = gitWorkTree + '.git'

        if to.gitBranch
          shell.exec("git --git-dir=#{ util.escapeShell(gitDir) } --work-tree=#{ util.escapeShell(gitWorkTree) } checkout #{ to.gitBranch }", { silent: !verbose })

        shell.exec("git --git-dir=#{ util.escapeShell(gitDir) } --work-tree=#{ util.escapeShell(gitWorkTree) } pull", { silent: !verbose })
        shell.exec("git --git-dir=#{ util.escapeShell(gitDir) } --work-tree=#{ util.escapeShell(gitWorkTree) } add -A", { silent: !verbose })

        gitPrefix = to.gitPrefix or "Resource update"
        message = globalOptions.gitMessage
        fullMessage = ''
        if message
          if gitPrefix then fullMessage = gitPrefix + ': ' + message else fullMessage = message
        else
          if gitPrefix then fullMessage = gitPrefix else fullMessage = "Resource update"
        gitRemote = to.gitRemote or "origin"
        gitBranch = to.gitBranch or ''

        shell.exec("git --git-dir=#{ util.escapeShell(gitDir) } --work-tree=#{ util.escapeShell(gitWorkTree) } commit -m '#{ fullMessage }'", { silent: !verbose })
        shell.exec("git --git-dir=#{ util.escapeShell(gitDir) } --work-tree=#{ util.escapeShell(gitWorkTree) } push #{ gitRemote } #{ gitBranch }", { silent: !verbose })

        process.stdout.write "Commited to git with message '#{ fullMessage }'\n" if verbose
      else
        process.stdout.write "Error: git is not installed.\n"
    else
      process.stdout.write "Error: gitRoot is required.\n"

  cb()

module.exports = (data, location, options) ->
  globalOptions = options
  verbose = options.verbose
  workflowLocation = location
  assetpress = require '../assetpress'

  queue = async.queue performWorkflow, 1
  queue.drain = -> # nil.

  if _.isArray data
    for workflowObject in data
      queue.push workflowObject
  else if _.isObject data
    queue.push data

