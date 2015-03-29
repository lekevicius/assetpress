fs = require 'fs-extra'
path = require 'path'
_ = require 'lodash'
walk = require 'walkdir'
androidAssetPress = require './assetpress-android'
iOSAssetPress = require './assetpress-ios'
workflow = require './assetpress-workflow'
util = require './utilities'

module.exports = (options) ->

  defaults = 
    inputDirectoryName: 'source'
    outputDirectoryName: false
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

  inputDirectory = util.resolvePath options.inputDirectoryName
  inputDetails = path.parse inputDirectory

  if inputDetails.ext.toLowerCase() is '.json' and _.endsWith(inputDetails.name.toLowerCase(), '.assetpress')
    workflowData = require inputDirectory
    workflow workflowData, inputDetails.dir, options
  else
    inputDirectory = util.addTrailingSlash inputDirectory
    return process.stdout.write "Input directory #{ inputDirectory } does not exist." if !fs.existsSync inputDirectory
      
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
      outputDirectoryName: options.outputDirectoryName
      complete: options.complete

    switch options.os
      when 'android'
        androidAssetPress inputDirectory, androidOptions, globalOptions
      when 'ios'
        iOSAssetPress inputDirectory, iosOptions, globalOptions
