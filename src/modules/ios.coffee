fs = require 'fs-extra'
path = require 'path'

_ = require 'lodash'
im = require('gm').subClass imageMagick: true
async = require 'async'
walk = require 'walkdir'

iOSAssetPressXCAssets = require './ios-xcassets'
util = require '../utilities'

scalerExceptions = 
  'Default-Landscape736h': minDensity: 3
  'Default-Portrait736h': minDensity: 3

deviceTypes = [
  'universal'
  'iphone'
  'ipad'
  'car'
  'watch'
]

allowedExtensions = []
directoryAllowedExtensions = [
  '.png'
  '.jpg'
  '.jpeg'
  '.gif'
]
xcassetsAllowedExtensions = [
  '.png'
  '.jpg'
  '.jpeg'
]

resizeFilter = 'Box'
inputDirectory = ''
outputDirectory = ''
globalOptions = {}
xcassets = false
verbose = false
minimumPhone = 2
maximumPhone = 3
minimumPad = 1
maximumPad = 2
minimum = 1
maximum = 3


processImage = (task, cb) ->
  info = task.info
  device = task.device
  scale = task.scale
  name = '' + scale
  highestScale = info.devices[device].highestScale
  return cb() if scale > highestScale
  fs.ensureDirSync outputDirectory + info.foldername
  highestScaleImagePath = inputDirectory + info.devices[device]['' + highestScale]
  image = im(highestScaleImagePath).out '-define', 'png:exclude-chunk=date'

  image.size (err, size) ->
    # unchangedOutputPath = ''
    imageWidth = size.width
    imageHeight = size.height
    scaleSuffix = if scale is 1 then '' else '@' + scale + 'x'
    deviceSuffix = if device is 'universal' then '' else '~' + device
    from = inputDirectory + info.devices[device][name]
    outputPath = info.id + scaleSuffix + deviceSuffix + info.extension

    if info.id.indexOf('AppIcon') is 0
      unchangedOutputPath = outputPath
      if !_.contains iOSAssetPressXCAssets.appIconList, iOSAssetPressXCAssets.bareFormat(outputPath, 'AppIcon')
        iPhoneOutputPath = info.id + scaleSuffix + '~iphone' + info.extension
        if _.contains iOSAssetPressXCAssets.appIconList, iOSAssetPressXCAssets.bareFormat(iPhoneOutputPath, 'AppIcon')
          device = task.device = 'iphone'
          deviceSuffix = '~iphone'
          outputPath = iPhoneOutputPath
        else
          process.stdout.write 'Unknown App Icon: ' + outputPath + '\n'
          cb()
          return
      # var expectedSize = getAppIconInfo(outputPath).size;
      # if (expectedSize !== imageWidth || expectedSize !== imageHeight) {
      #   process.stdout.write(
      #     "WARNING: App Icon " + unchangedOutputPath + " should be " + expectedSize + "x" + expectedSize + 
      #     ", but it is " + imageWidth + "x" + imageHeight + ".\n");
      # }

    if info.id.indexOf('Default') is 0
      unchangedOutputPath = outputPath
      if !_.contains( iOSAssetPressXCAssets.launchImageList, outputPath)
        iPhoneOutputPath = '' + info.id + scaleSuffix + '~iphone' + info.extension
        if _.contains(iOSAssetPressXCAssets.launchImageList, iPhoneOutputPath)
          device = task.device = 'iphone'
          deviceSuffix = '~iphone'
          outputPath = iPhoneOutputPath
        else
          process.stdout.write 'Unknown Launch Image: ' + outputPath + '\n'
          cb()
          return

      # var launchImageInfo = getLaunchImageInfo(outputPath);
      # var expectedWidth = launchImageInfo.width;
      # var expectedHeight = launchImageInfo.height;
      # if (expectedWidth !== imageWidth || expectedHeight !== imageHeight) {
      #   process.stdout.write(
      #     "WARNING: Launch Image " + unchangedOutputPath + " should be " + expectedWidth + "x" + expectedHeight + 
      #     ", but it is " + imageWidth + "x" + imageHeight + ".\n");
      # }

    if xcassets
      if info.id.indexOf('AppIcon') is 0
        appIconRoot = info.id.split(/-|~|@/)[0]
        appIconRootSuffix = appIconRoot.substr(7) # AppIcon
        outputPath = "AppIcon#{ appIconRootSuffix }.appiconset/" + info.id + scaleSuffix + deviceSuffix + info.extension
        fs.ensureDirSync outputDirectory + "AppIcon#{ appIconRootSuffix }.appiconset/"
      else if info.id.indexOf('Default') is 0
        outputPath = 'LaunchImage.launchimage/' + info.id + scaleSuffix + deviceSuffix + info.extension
        fs.ensureDirSync outputDirectory + 'LaunchImage.launchimage/'
      else
        outputPath = info.foldername + info.basename + '.imageset/' + info.basename + scaleSuffix + deviceSuffix + info.extension
        fs.ensureDirSync outputDirectory + info.foldername + info.basename + '.imageset/'

    to = outputDirectory + outputPath
    if _.has info.devices[device], name
      fs.copy from, to, ->
        process.stdout.write 'Copied prerendered image ' + info.id + scaleSuffix + deviceSuffix + info.extension + '\n' if verbose
        cb()
    else
      scaleRatio = scale / highestScale
      image
      .filter resizeFilter
      .resize Math.round(imageWidth * scaleRatio), Math.round(imageHeight * scaleRatio), '!'
      .write to, (err) ->
        process.stdout.write err + '\n' if err
        process.stdout.write 'Scaled image ' + info.id + scaleSuffix + deviceSuffix + info.extension + '\n' if verbose
        cb()

describeInputDirectory = (input) ->
  paths = walk.sync input
  paths = _.map paths, (filepath) -> filepath.replace input, ''
  filtered = _.filter paths, (filepath) ->
    filepath = path.join input, filepath
    return false if !fs.lstatSync(filepath).isFile()
    basename = path.basename filepath
    return false if basename.slice(0, 1) == '.'
    extension = path.extname filepath
    if !_.contains allowedExtensions, extension
      process.stdout.write 'File ' + filepath + ' in unsupported format for current output.\n'
      return false
    pathSegments = filepath.split '/'
    pathSegments.pop()
    return false for segment in pathSegments when segment.slice(0, 1) is '_'
    true

  grouped = _.groupBy filtered, (filepath) ->
    filepath
    .slice 0, path.extname(filepath).length * -1
    .replace(/@(\d+)x/, '')
    .replace(/~([a-z]+)/, '')

  imageDescriptors = []
  for identifier of grouped
    paths = grouped[identifier]
    descriptor = 
      id: identifier
      devices: {}
    pathSegments = identifier.split '/'
    if pathSegments.length > 1
      pathSegments.pop()
      descriptor.foldername = pathSegments.join('/') + '/'
    else
      descriptor.foldername = ''
    descriptor.basename = identifier.split('/').pop()
    descriptor.extension = path.extname paths[0]
    descriptor.extension = '.jpg' if descriptor.extension == '.jpeg'
      
    for filepath in paths
      extension = path.extname filepath
      namepath = filepath.slice 0, extension.length * -1
      scaleMatch = namepath.match /@(\d+)x/
      scale = if scaleMatch then parseInt scaleMatch[1] else 1
      deviceMatch = namepath.match /~([a-z]+)/i
      device = if deviceMatch then deviceMatch[1].toLowerCase() else 'universal'
      descriptor.devices[device] = {} if !_.has descriptor.devices, device
      descriptor.devices[device][scale] = filepath

    for device, paths of descriptor.devices
      maxScale = _.max _.keys(paths), (key) -> parseInt key
      descriptor.devices[device].highestScale = parseInt maxScale

    delete descriptor.devices.universal if (
      ( _.has(descriptor.devices, 'iphone') or _.has(descriptor.devices, 'ipad') ) and 
      _.has(descriptor.devices, 'universal') and
      xcassets and 
      !( identifier.indexOf('AppIcon') == 0 or identifier.indexOf('Default') == 0 )
    )
    imageDescriptors.push descriptor
  imageDescriptors

module.exports = (directory, options, globalSettings) ->
  globalOptions = globalSettings
  verbose = globalOptions.verbose
  xcassets = options.xcassets
  allowedExtensions = if xcassets then xcassetsAllowedExtensions else directoryAllowedExtensions
  minimumPhone = options.minimumPhone
  maximumPhone = options.maximumPhone
  minimumPad = options.minimumPad
  maximumPad = options.maximumPad
  minimum = options.minimum
  maximum = options.maximum
  inputDirectory = directory
  outputDirectoryName = globalOptions.outputDirectoryName or 'Images'
  outputDirectoryName = util.removeTrailingSlash outputDirectoryName
  outputDirectoryName = outputDirectoryName + '.xcassets' if xcassets
  outputDirectoryBase = util.resolvePath '..', inputDirectory
  outputDirectory = util.resolvePath outputDirectoryName, outputDirectoryBase
  outputDirectory = util.addTrailingSlash outputDirectory
  fs.removeSync outputDirectory if globalOptions.clean
  fs.ensureDirSync outputDirectory

  queue = async.queue processImage, 4
  queue.drain = -> 
    if xcassets
      iOSAssetPressXCAssets.createContentsJSON(outputDirectory, globalOptions)
    else
      globalOptions.complete()

  imageDescriptors = describeInputDirectory inputDirectory

  for device in deviceTypes
    switch device
      when 'iphone'
        minDensity = minimumPhone
        maxDensity = maximumPhone
        absoluteMinDensity = 1
        absoluteMaxDensity = 3
      when 'ipad'
        minDensity = minimumPad
        maxDensity = maximumPad
        absoluteMinDensity = 1
        absoluteMaxDensity = 2
      when 'car'
        minDensity = 1
        maxDensity = 1
        absoluteMinDensity = 1
        absoluteMaxDensity = 1
      when 'watch'
        minDensity = 2
        maxDensity = 2
        absoluteMinDensity = 2
        absoluteMaxDensity = 3
      when 'universal'
        minDensity = minimum
        maxDensity = maximum
        absoluteMinDensity = 1
        absoluteMaxDensity = 3

    for descriptor in imageDescriptors
      if _.has descriptor.devices, device
        adjustedMinDensity = minDensity
        adjustedMaxDensity = maxDensity
        if _.has scalerExceptions, descriptor.id
          adjustments = scalerExceptions[descriptor.id]
          adjustedMinDensity = adjustments.minDensity if adjustments.minDensity
          adjustedMaxDensity = adjustments.maxDensity if adjustments.maxDensity
        scale = adjustedMinDensity
        while scale <= adjustedMaxDensity
          queue.push
            info: descriptor
            device: device
            scale: scale
          scale++
        # Don't skip any pre-rendered images
        for scale of descriptor.devices[device]
          if scale is 'highestScale'
            scale++
            continue
          scale = parseInt scale
          if (
            (scale < adjustedMinDensity or scale > adjustedMaxDensity) and
            scale >= absoluteMinDensity and
            scale <= absoluteMaxDensity
          )
            queue.push
              info: descriptor
              device: device
              scale: scale
