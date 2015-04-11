fs = require 'fs-extra'
path = require 'path'

_ = require 'lodash'
walk = require 'walkdir'
async = require 'async'
tmp = require 'temporary'
shell = require 'shelljs'

androidResizer = require './modules/android'
iOSResizer = require './modules/ios'
splitter = require './modules/splitter'
git = require './modules/git'
util = require './utilities'

options = {}

defaults = 
  # Common Options
  verbose: false
  clean: false
  # Resizer Options
  inputDirectory: 'source'
  outputDirectory: false
  os: 'ios'
  # Splitter Options
  screensDirectory: false
  noResize: false
  # Workflow Object or JSON String - uses already defined object intead of setting up one.
  workflowObject: false
  # Workflow Git
  gitMessage: false
  gitRoot: false
  gitBranch: false
  gitPrefix: false
  gitRemote: false
  gitNoPush: false

module.exports = (passedOptions, callback = false) ->
  
  # Option grooming
  options = _.defaults passedOptions, defaults
  unless callback then callback = -> # noop
  
  # Input directory parsing
  inputDirectory = util.resolvePath options.inputDirectory
  inputDetails = path.parse inputDirectory
  
  # Everything runs as workflow
  queue = async.queue performWorkflow, 1
  queue.drain = -> # nil

  # AssetPress running option #1: workflowObject string or object, or Workflow File (.assetpress.json) file as input.
  # It runs the workflow(s) as they are defined, and will not do anything more. It trusts pre-formed workflow.
  if options.workflowObject or (inputDetails.ext.toLowerCase() is '.json' and _.endsWith(inputDetails.name.toLowerCase(), '.assetpress'))
    if options.workflowObject
      options.workflowObject = JSON.parse(options.workflowObject) if _.isString options.workflowObject
      options.workflowObject.location = path.resolve '..'
    else
      options.workflowObject = require inputDirectory
      options.workflowObject.location = inputDetails.dir
    options.workflowObject.verbose = options.verbose
      
    if _.isArray options.workflowObject
      for singleObject in options.workflowObject
        queue.push singleObject
    else if _.isObject options.workflowObject
      queue.push options.workflowObject

  # AssetPress running option #2: forming its own workflow from all the options, and running it
  else 
    workflowObject = {
      location: path.resolve '..'
      verbose: options.verbose
    }
    
    # Form source
    workflowObject.source = inputDirectory
    
    # Form assetpress
    commonKeys = [ 'verbose', 'os' ]
    if options.os is 'ios'
      osKeys = [ 'iosMinimum', 'iosMaximum', 'iosMinimumPhone', 'iosMaximumPhone', 'iosMinimumPad', 'iosMaximumPad', 'iosXcassets' ]
    else
      osKeys = [ 'androidLdpi', 'androidXxxhdpi' ]
    workflowObject.assetpress = _.pick options, _.merge( commonKeys, osKeys )
    
    # Form screens
    if options.noResize then delete workflowObject.assetpress
    if options.screensDirectory
      workflowObject.screens = {
        destination: util.resolvePath inputDetails.dir, options.screensDirectory
        clean: options.clean
      }
    
    # Form output
    workflowObject.output = {
      destination: options.outputDirectory
      clean: options.clean
    }
    
    queue.push options.workflowObject


performWorkflow = (workflowObject, callback) ->
  
  # Normalize input path
  workflowObject.source = util.resolvePath workflowObject.location, workflowObject.source
  # Validate that it exists
  if !fs.existsSync workflowObject.source
    process.stdout.write "Error: Source #{ workflowObject.source } does not exist.\n"
    return callback()

  # Normalize output object, making sure it it follows the structure { destination: "", clean: Bool }
  # suggestedDestination key means that output path is speculative, and can be re-adjusted.
  outputObject = {
    destination: util.resolvePath workflowObject.source, "../#{ path.basename(workflowObject.source, '.sketch') } Resources"
    suggestedDestination: true
  }
  if workflowObject.output
    if _.isString(workflowObject.output)
      outputObject = { 
        destination: util.resolvePath(workflowObject.location, workflowObject.output)
        clean: false
      }
    else if workflowObject.output.destination and _.isString(workflowObject.output.destination)
        outputObject = workflowObject.output
        outputObject.destination = util.resolvePath(workflowObject.location, workflowObject.output.destination)
        outputObject.clean = false unless _.has outputObject, 'clean'
  workflowObject.output = outputObject

  # Verifying that destination is not inside source. It's not a very stable configuration.
  if workflowObject.output.destination.indexOf( util.addTrailingSlash workflowObject.source ) is 0
    process.stdout.write "ERROR: output destination is inside source.\n"
    return callback()
    
  temporaryDirectoryObject = new tmp.Dir
  temporaryDirectory = util.addTrailingSlash temporaryDirectoryObject.path
  temporarySourceDirectory = temporaryDirectory + 'source'

  # First step of workflow is to prepare source directory
  # If it already is a directory, copy everything to temporary directory
  # TODO avoid copying, instead try to use it from current location
  if fs.lstatSync(workflowObject.source).isDirectory()
    fs.copySync sourcePath, temporarySourceDirectory
      
  # Another possible input is Sketch file
  else if path.extname(workflowObject.source).toLowerCase() is '.sketch'
    
    # Sketchtool is required
    unless shell.which('sketchtool')
      process.stdout.write "ERROR: Sketchtool is required. Download it from http://bohemiancoding.com/sketch/tool/\n"
      fs.removeSync temporaryDirectory
      return callback()
      
    # The magic Sketchtool command
    shellOutput = shell.exec(
      "sketchtool export slices --output=#{ util.escapeShell(temporaryDirectory + 'source') } #{ util.escapeShell(workflowObject.source) }", 
      { silent: !workflowObject.verbose })
  
  # So far those are the only two input options
  else
    process.stdout.write "ERROR: AssetPress workflow currently only accepts directories and Sketch files as source.\n"
    fs.removeSync temporaryDirectory
    return callback()

  # Next (optional) step is running Splitter
  # Normalize string or object into the structure { destination: "", clean: Bool }
  if workflowObject.screens
    screensObject = {
      source: temporarySourceDirectory
      resourcesDestination: '.'
      screensDestination: util.resolvePath workflowObject.source, '../Screen Previews'
      options: {
        verbose: workflowObject.verbose
        clean: false
      }
    }
    if _.isString(workflowObject.screens)
      screensObject.screensDestination = util.resolvePath workflowObject.location, workflowObject.screens
    else
      screensObject.screensDestination = util.resolvePath workflowObject.location, workflowObject.screens.destination
      screensObject.options.clean = workflowObject.screens.clean if _.has workflowObject.screens, 'clean'
    
    splitter screensObject
    process.stdout.write "Split screens to #{ screensPath }.\n" if workflowObject.verbose

  # Finally, coming to AssetPress! (optionally)

  if workflowObject.assetpress and _.isObject workflowObject.assetpress

    # Complaining about unset OS
    unless workflowObject.assetpress.os
      process.stdout.write "WARNING: Running AssetPress with iOS implied. Please set 'os' value in assetpress object.\n"
      workflowObject.assetpress.os = 'ios'
      
    if workflowObject.assetpress.os is 'ios' and workflowObject.assetpress.iosXcassets and workflowObject.output.suggestedDestination
      workflowObject.output.destination = util.removeTrailingSlash(outputObject.destination) + '.xcassets'

    completeFunction = -> 
      process.stdout.write "Completed AssetPress for #{ sourcePath }\n" if workflowObject.verbose
      completeWorkflow workflowObject, temporaryDirectory, callback

    # Ready to run either androidResizer or iOSResizer
    switch workflowObject.assetpress.os 
      when 'android'
        androidOptions = 
          # Common options
          verbose: workflowObject.verbose
          clean: workflowObject.output.clean
          # Android-specific options
          ldpi: workflowObject.assetpress.androidLdpi
          xxxhdpi: workflowObject.assetpress.androidXxxhdpi
        androidResizer temporarySourceDirectory, workflowObject.output.destination, androidOptions, completeFunction

      when 'ios'
        iosOptions = 
          # Common options
          verbose: workflowObject.verbose
          clean: workflowObject.output.clean
          # iOS-specific options
          minimum: parseInt workflowObject.assetpress.iosMinimum
          maximum: parseInt workflowObject.assetpress.iosMaximum
          minimumPhone: parseInt workflowObject.assetpress.iosMinimumPhone
          maximumPhone: parseInt workflowObject.assetpress.iosMaximumPhone
          minimumPad: parseInt workflowObject.assetpress.iosMinimumPad
          maximumPad: parseInt workflowObject.assetpress.iosMaximumPad
          xcassets: workflowObject.assetpress.iosXcassets
        iOSResizer temporarySourceDirectory, workflowObject.output.destination, iosOptions, completeFunction
        
  else
    # If user has specified output...
    unless outputObject.suggestedDestination
      # WorkflowObject could have source, (screens - optional), output
      # If just source and output, move source to output, cleanly or not.
      # Additional screens step does not change anything.
      util.move temporarySourceDirectory, workflowObject.output.destination, workflowObject.output.clean
      process.stdout.write "Moved output to #{ to.destination }\n" if workflowObject.verbose
      completeWorkflow workflowObject, temporaryDirectory, callback
    else
      # Otherwise, we have nothing to do.
      # That happens if user has only source (pointless) or source and screens (using only splitter function)
      fs.removeSync temporaryDirectory
      callback()

completeWorkflow = (workflowObject, temporaryDirectory, callback) ->
  # By now everything is done, all assetpress assets are moved into output
  # Remaining steps: do git commit, remove temporary folder, and be done
  fs.removeSync temporaryDirectory
  
  if workflowObject.output.gitRoot
    gitOptions = {
      verbose: workflowObject.verbose
      branch: workflowObject.output.gitBranch
      prefix: workflowObject.output.gitPrefix
      remote: workflowObject.output.gitRemote
      noPush: workflowObject.output.gitNoPush
    }
    git workflowObject.output.gitRoot, workflowObject.output.gitMessage, gitOptions, callback
  else
    callback()
