fs = require 'fs-extra'
path = require 'path'

_ = require 'lodash'
im = require('gm').subClass imageMagick: true
async = require 'async'
walk = require 'walkdir'
tmp = require 'temporary'

iOSXCAssets = require './ios-xcassets'
iOSConstants = require './ios-constants'
util = require '../utilities'

inputDirectory = ''
outputDirectory = ''
temporaryDirectory = ''
options = {}

defaults =
  minimum: 1
  maximum: 3
  minimumPhone: 2
  maximumPhone: 3
  minimumPad: 1
  maximumPad: 2
  xcassets: false

processImage = (task, callback) ->
  
  info = task.info # Entire descriptor
  scaleKey = '' + task.scale # Lookup key
  highestScale = info.devices[task.device].highestScale
  
  # iOS scaling naming: nothing, @2x, @3x...
  scaleSuffix = if task.scale is 1 then '' else "@#{ task.scale }x"
  # Universal resources are simply icon@2x.png, device specific are icon@2x~iphone.png
  # AssetPress accepts both icon@2x~iphone.png (correct) and icon~iphone@2x.png (incorrect)
  deviceSuffix = if task.device is 'universal' then '' else '~' + task.device

  if task.scale > highestScale
    # If we were expecting 3x image, but only 2x was provided, don't upscale.
    if ( info.id.indexOf('AppIcon') isnt 0 and info.id.indexOf('Default') isnt 0 )
      # Mr. Complainy Pants. Doesn't complain about AppIcons and Launch Images, but does complain about missing resolutions.
      process.stdout.write "WARNING: Missing image #{ info.id + scaleSuffix + deviceSuffix + info.extension }\n"
    return callback()

  fs.ensureDirSync temporaryDirectory + info.foldername

  # Setting up image
  # If file exists, it will copied, so no need to load highest scale version
  if _.has info.devices[task.device], scaleKey
    image = im(info.devices[task.device][scaleKey])
  # Otherwise, it will be scaled down, so we load highest scale version
  else
    image = im(info.devices[task.device]['' + highestScale])
    # Making sure ImageMagic doesn't add date chunk that creates a binary difference where there are none.
    .out '-define', 'png:exclude-chunk=date'

  image.size (err, size) ->
    process.stdout.write err + '\n' if err

    # 1. Make sure that this resource is correct and needed.

    outputPath = info.id + scaleSuffix + deviceSuffix + info.extension

    # Additional check for AppIcons: making sure such icon really exists.
    if info.id.indexOf('AppIcon') is 0
      unchangedOutputPath = outputPath
      # Checking unmodified name and iPhone-specific version
      iPhoneOutputPath = info.id + scaleSuffix + '~iphone' + info.extension
      # For app icons we are also using bareFormat function, so both AppIcon and AppIconTestfligh works.
      if (
        _.contains(iOSConstants.appIconList, iOSConstants.bareFormat(outputPath, 'AppIcon')) or
        _.contains(iOSConstants.appIconList, iOSConstants.bareFormat(iPhoneOutputPath, 'AppIcon'))
      )
        # If we only found iPhone-specific image, modify variables accordingly
        if (
          !_.contains(iOSConstants.appIconList, iOSConstants.bareFormat(outputPath, 'AppIcon')) and
          _.contains(iOSConstants.appIconList, iOSConstants.bareFormat(iPhoneOutputPath, 'AppIcon'))
        )
          task.device = 'iphone'
          deviceSuffix = '~iphone'
          outputPath = iPhoneOutputPath

        # Found App Icon, verify size.
        expectedSize = iOSConstants.getAppIconInfo(outputPath).size
        if expectedSize isnt size.width or expectedSize isnt size.height
          process.stdout.write "WARNING: App Icon #{ unchangedOutputPath } should be #{ expectedSize }x#{ expectedSize }, but it is #{ size.width }x#{ size.height }.\n"
      else
        process.stdout.write "WARNING: Unknown App Icon #{ outputPath }\n"
        return callback()

    # Same checks for Launch Images
    if info.id.indexOf('Default') is 0
      unchangedOutputPath = outputPath
      iPhoneOutputPath = info.id + scaleSuffix + '~iphone' + info.extension
      if (
        _.contains(iOSConstants.launchImageList, outputPath) or
        _.contains(iOSConstants.launchImageList, iPhoneOutputPath)
      )
        if (
          !_.contains(iOSConstants.launchImageList, outputPath) and
          _.contains(iOSConstants.launchImageList, iPhoneOutputPath)
        )
          task.device = 'iphone'
          deviceSuffix = '~iphone'
          outputPath = iPhoneOutputPath

        # Found Launch Image, verify size.
        launchImageInfo = iOSConstants.getLaunchImageInfo outputPath
        expectedWidth = launchImageInfo.width
        expectedHeight = launchImageInfo.height
        if expectedWidth isnt size.width or expectedHeight isnt size.height
          process.stdout.write "WARNING: Launch Image #{ unchangedOutputPath } should be #{ expectedWidth }x#{ expectedHeight }, but it is #{ size.width }x#{ size.height }.\n"
      else
        process.stdout.write "WARNING: Unknown Launch Image #{ outputPath }\n"
        return callback()

    # 2. Update output path for Xcassets

    if options.xcassets
      if info.id.indexOf('AppIcon') is 0
        appIconRoot = info.id.split(/-|~|@/)[0]
        appIconRootSuffix = appIconRoot.substr(7) # AppIcon | Testflight
        outputPath = "AppIcon#{ appIconRootSuffix }.appiconset/" + info.id + scaleSuffix + deviceSuffix + info.extension
        fs.ensureDirSync path.resolve(temporaryDirectory, "AppIcon#{ appIconRootSuffix }.appiconset/")
      else if info.id.indexOf('Default') is 0
        outputPath = 'LaunchImage.launchimage/' + info.id + scaleSuffix + deviceSuffix + info.extension
        fs.ensureDirSync path.resolve(temporaryDirectory, 'LaunchImage.launchimage/')
      else
        outputPath = info.id + '.imageset/' + info.basename + scaleSuffix + deviceSuffix + info.extension
        fs.ensureDirSync path.resolve(temporaryDirectory, info.id + '.imageset/')

    # 3. Final action is copy or resize

    destinationPath = path.resolve temporaryDirectory, outputPath

    # If the file already exists, we need to copy it.
    if _.has info.devices[task.device], scaleKey
      if info.id.indexOf('AppIcon') is 0
        # For App Icons we always remove alpha channel.
        # It is a requirement by Apple.
        image
        .out '-background', 'white'
        .out '-alpha', 'remove'
        .out '-define', 'png:exclude-chunk=date'
        .write destinationPath, (err) ->
          process.stdout.write err + '\n' if err
          process.stdout.write "Copied prerendered App Icon #{ info.id + scaleSuffix + deviceSuffix + info.extension } and removed alpha channel.\n" if options.verbose
          return callback()
      else
        fs.copy info.devices[task.device][scaleKey], destinationPath, ->
          process.stdout.write "Copied prerendered image #{ info.id + scaleSuffix + deviceSuffix + info.extension }\n" if options.verbose
          return callback()
    # Otherwise, scale down the highest scale image
    else
      scaleRatio = task.scale / highestScale
      image
      .filter iOSConstants.resizeFilter
      .resize Math.round(size.width * scaleRatio), Math.round(size.height * scaleRatio), '!'
      .out '-background', 'white'
      .out '-alpha', 'remove'
      .out '-define', 'png:exclude-chunk=date'
      .write destinationPath, (err) ->
        process.stdout.write err + '\n' if err
        process.stdout.write "Scaled image #{ info.id + scaleSuffix + deviceSuffix + info.extension }\n" if options.verbose
        return callback()

# Takes a directory and returns an object with files grouped, organized by device and scale.
describeInputDirectory = (inputDirectory) ->

  # Constructs list of files in input directory, with input directory path removed.
  paths = _.map walk.sync(inputDirectory), (filepath) -> filepath.replace inputDirectory, ''

  # Extention whitelist
  allowedExtensions = if options.xcassets then iOSConstants.xcassetsAllowedExtensions else iOSConstants.directoryAllowedExtensions

  filtered = _.filter paths, (filepath) ->

    # Drop if not a file (we can't resize a directory)
    return false if !fs.lstatSync( path.resolve(inputDirectory, filepath) ).isFile()

    # Drop if it's a hidden file (filename starts with .)
    return false if path.basename(filepath).slice(0, 1) == '.'

    # Drop if file extension is not in the whitelist
    extension = path.extname filepath
    if !_.contains allowedExtensions, extension
      process.stdout.write "File #{ filepath } in unsupported format for current output.\n"
      return false

    # Drop everything that has _ anywhere in path
    pathSegments = util.removeTrailingSlash(filepath).split '/'
    return false for segment in pathSegments when segment.slice(0, 1) is '_'

    # Everything else shall pass
    true

  # Bundles related files together
  grouped = _.groupBy filtered, (filepath) ->
    filepath
    .slice 0, path.extname(filepath).length * -1 # We don't care about extention
    .replace(/@(\d+)x/, '') # Scale
    .replace(/~([a-z]+)/, '') # Or device
    # Conveniently, this returns a common name for resource, that is used as a key, for example icons/menuIcon

  # Image descriptors is a list of objects that describe these bundled groups in detail.
  imageDescriptors = []
  for identifier of grouped
    groupPaths = grouped[identifier]

    descriptor = 
      id: identifier
      basename: path.basename identifier
      extension: path.extname groupPaths[0]
      devices: {}

    descriptor.foldername = path.dirname identifier
    if descriptor.foldername is '.' then descriptor.foldername = '' else descriptor.foldername += '/'
    
    # Normalize JPEG extension for later.
    descriptor.extension = '.jpg' if descriptor.extension == '.jpeg'
      
    for filepath in groupPaths
      # Scale
      scaleMatch = filepath.match /@(\d+)x/
      scale = if scaleMatch then parseInt scaleMatch[1] else 1
      # Device
      deviceMatch = filepath.match /~([a-z]+)/i
      device = if deviceMatch then deviceMatch[1].toLowerCase() else 'universal'
      # Add this, so its descriptor.devices.universal.2
      descriptor.devices[device] = {} if !_.has descriptor.devices, device
      descriptor.devices[device][scale] = path.resolve inputDirectory, filepath

    # Images will be scaled down from the highest scale image (4x recommended)
    for device, groupPaths of descriptor.devices
      highestScale = _.max _.keys(groupPaths), (key) -> parseInt key
      descriptor.devices[device].highestScale = parseInt highestScale

    # In Xcassets folder both device-specific and universal resources are not allowed,
    # If descriptor.devices has both, univeral is removed.
    if (
      options.xcassets and 
      ( _.has(descriptor.devices, 'iphone') or _.has(descriptor.devices, 'ipad') ) and 
      _.has(descriptor.devices, 'universal') and
      !( identifier.indexOf('AppIcon') == 0 or identifier.indexOf('Default') == 0 )
    )
      delete descriptor.devices.universal

    imageDescriptors.push descriptor
  imageDescriptors

module.exports = (passedInputDirectory, passedOutputDirectory = false, passedOptions = {}, callback = false) ->

  inputDirectory = util.addTrailingSlash util.resolvePath(passedInputDirectory)
  outputDirectory = passedOutputDirectory
  options = _.defaults passedOptions, defaults
  unless callback then callback = -> # noop
  
  # Numberify options
  options.minimum = parseInt options.minimum
  options.maximum = parseInt options.maximum
  options.minimumPhone = parseInt options.minimumPhone
  options.maximumPhone = parseInt options.maximumPhone
  options.minimumPad = parseInt options.minimumPad
  options.maximumPad = parseInt options.maximumPad

  outputDirectoryName = if passedOutputDirectory then util.removeTrailingSlash(passedOutputDirectory) else 'Images' 
  outputDirectoryName += '.xcassets' if options.xcassets and !_.endsWith(outputDirectoryName, '.xcassets')

  outputDirectoryBase = util.resolvePath inputDirectory, '..'
  outputDirectory = util.addTrailingSlash util.resolvePath(outputDirectoryBase, outputDirectoryName)

  temporaryDirectoryObject = new tmp.Dir
  temporaryDirectory = util.addTrailingSlash temporaryDirectoryObject.path

  queue = async.queue processImage, 1
  queue.drain = -> 
    # These are the final actions: moving results from temporary folder to final output
    util.move temporaryDirectory, outputDirectory, options.clean
    # And removing temporary folder.
    fs.removeSync temporaryDirectory
    # We either end here or continue with XCAssets JSONs
    if options.xcassets
      iOSXCAssets outputDirectory, { verbose: options.verbose }, callback
    else
      callback()

  # Image descriptors is the master data, that describes all image groups
  imageDescriptors = describeInputDirectory inputDirectory
  
  # Very useful debug line
  # console.log require('util').inspect(imageDescriptors, false, null)

  for device in iOSConstants.deviceTypes
    # min and max densities make sure that all needed scales are created.
    # min and max absolute densities make sure that impossible scales (4x+) are not created.
    [ minDensity, maxDensity, absoluteMinDensity, absoluteMaxDensity ] = iOSConstants.getDensityLimits(device, options)

    for descriptor in imageDescriptors
      if _.has descriptor.devices, device

        # Here we deal with certain exceptions
        adjustedMinDensity = minDensity
        adjustedMaxDensity = maxDensity
        if _.has iOSConstants.scalerExceptions, descriptor.id
          adjustments = iOSConstants.scalerExceptions[descriptor.id]
          adjustedMinDensity = adjustments.minDensity if adjustments.minDensity
          adjustedMaxDensity = adjustments.maxDensity if adjustments.maxDensity

        # Set up all expected results
        scale = adjustedMinDensity
        while scale <= adjustedMaxDensity
          queue.push
            info: descriptor
            device: device
            scale: scale
          scale++

        # Don't skip any pre-rendered images, unless they are beyond maximum limits.
        for scale of descriptor.devices[device]
          # TODO all these 3 lines - what do they do?
          if scale is 'highestScale'
            scale++ 
            continue

          scale = parseInt scale
          if (
            (scale < adjustedMinDensity or scale > adjustedMaxDensity) and # Otherwise it is already generated
            scale >= absoluteMinDensity and scale <= absoluteMaxDensity # Not beyond maximum limits
          )
            queue.push
              info: descriptor
              device: device
              scale: scale
