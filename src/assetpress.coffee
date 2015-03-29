fs = require 'fs-extra'
path = require 'path'

_ = require 'lodash'
walk = require 'walkdir'

androidAssetPress = require './modules/android'
iOSAssetPress = require './modules/ios'
workflow = require './modules/workflow'
splitter = require './modules/splitter'
util = require './utilities'

module.exports = (options) ->

  defaults = 
    inputDirectory: 'source'
    outputDirectory: false
    screensDirectory: false
    noResize: false
    verbose: false
    clean: false
    os: 'ios'
    androidLdpi: false
    androidXxxhdpi: false
    iosMinimum: 1
    iosMaximum: 3
    iosMinimumPhone: 2
    iosMaximumPhone: 3
    iosMinimumPad: 1
    iosMaximumPad: 2
    iosXcassets: false
    gitMessage: false
    complete: -> # noop
  options = _.defaults options, defaults
  options.inputDirectory = 'source' if options.inputDirectory is true

  inputDirectory = util.resolvePath options.inputDirectory
  inputDetails = path.parse inputDirectory

  options.screensDirectory = path.basename(inputDirectory, '.sketch') + ' Screens' if options.screensDirectory is true

  if inputDetails.ext.toLowerCase() is '.json' and _.endsWith(inputDetails.name.toLowerCase(), '.assetpress')
    workflowData = require inputDirectory
    workflow workflowData, inputDetails.dir, options
  else if inputDetails.ext.toLowerCase() is '.sketch'
    workflowData = {
      source: inputDirectory
      assetpress: options
      screens: options.screensDirectory
    }
    workflow workflowData, inputDetails.dir, options
  else
    inputDirectory = util.addTrailingSlash inputDirectory
    return process.stdout.write "Input directory #{ inputDirectory } does not exist." if !fs.existsSync inputDirectory
    
    if options.screensDirectory and _.isString(options.screensDirectory)
      screensPath = util.resolvePath options.screensDirectory, inputDetails.dir
      splitter {
        source: inputDirectory
        resourcesDestination: '.'
        screensDestination: screensPath
      }
      process.stdout.write "Split screens to #{ screensPath }\n" if options.verbose

    console.log options
    if options.noResize
      options.complete()
      return

    androidOptions = 
      ldpi: options.androidLdpi
      xxxhdpi: options.androidXxxhdpi

    iosOptions = 
      minimum: parseInt options.iosMinimum
      maximum: parseInt options.iosMaximum
      minimumPhone: parseInt options.iosMinimumPhone
      maximumPhone: parseInt options.iosMaximumPhone
      minimumPad: parseInt options.iosMinimumPad
      maximumPad: parseInt options.iosMaximumPad
      xcassets: options.iosXcassets

    globalOptions = 
      verbose: options.verbose
      clean: options.clean
      outputDirectoryName: options.outputDirectory
      complete: options.complete

    switch options.os
      when 'android'
        androidAssetPress inputDirectory, androidOptions, globalOptions
      when 'ios'
        iOSAssetPress inputDirectory, iosOptions, globalOptions
