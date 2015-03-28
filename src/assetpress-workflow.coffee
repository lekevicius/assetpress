fs = require 'fs-extra'
path = require 'path'
_ = require 'lodash'
walk = require 'walkdir'
tmp = require 'temporary'
androidAssetPress = require './assetpress-android'
iOSAssetPress = require './assetpress-ios'
workflow = require './assetpress-workflow'
util = require './utilities'
shell = require 'shelljs'

verbose = false
workflowLocation = ''

performWorkflow = (workflowObject) ->
  console.log workflowObject

  sourcePath = util.resolvePath workflowObject.source, workflowLocation
  return process.stdout.write "Source #{ sourcePath } does not exist." if !fs.existsSync sourcePath

  temporaryDirectoryObject = new tmp.Dir
  temporaryDirectory = temporaryDirectoryObject.path
  temporaryDirectory += '/' if temporaryDirectory.slice(-1) isnt '/'
  console.log temporaryDirectory
  # shell.exec("open #{ util.escapeShell(temporaryDirectory) }", { silent: true })

  

  if fs.lstatSync(sourcePath).isDirectory()
    fs.copySync sourcePath, temporaryDirectory + 'source'
  else
    sourceDetails = path.parse sourcePath
    if sourceDetails.ext.toLowerCase() is '.sketch'
      if shell.which('sketchtool')
        shellOutput = shell.exec("sketchtool export slices --output=#{ util.escapeShell(temporaryDirectory + 'source') } #{ util.escapeShell(sourcePath) }", { silent: true })
        # console.log "OUT", shellOutput.output
      else
        return process.stdout.write "Sketchtool is required. Download it from http://bohemiancoding.com/sketch/tool/"
    else
      return process.stdout.write "AssetPress workflow currently only accepts directories and Sketch files as source."

  # * Write Moses
  # * Do splitting and moving previews
  # * Run assetpress with correct options on source
  # * Move output to given directory
  # Or, if its a git folder, do all the git things
  # DOABLE TODAY

module.exports = (data, location, options) ->
  verbose = options.verbose
  workflowLocation = location

  if _.isArray data
    performWorkflow(workflowObject) for workflowObject in data
  else if _.isObject data
    performWorkflow(data)

