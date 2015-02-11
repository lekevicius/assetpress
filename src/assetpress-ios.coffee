im = require('gm').subClass imageMagick: true
fs = require 'fs-extra'
path = require 'path'
_ = require 'lodash'
async = require 'async'
walk = require 'walkdir'

appIconGroups = 
  iOS8:
    'AppIcon-Settings@3x~iphone.png':
      size: 87
    'AppIcon-Spotlight@3x~iphone.png':
      size: 120
    'AppIcon@3x~iphone.png':
      size: 180

  iPhone:
    'AppIcon-Settings@2x~iphone.png':
      size: 58
      conflicts: [ 'AppIconLegacy-Small@2x~iphone.png' ]
    'AppIcon-Spotlight@2x~iphone.png':
      size: 80
    'AppIcon@2x~iphone.png':
      size: 120

  iPad:
    'AppIcon-Settings~ipad.png':
      size: 29
      conflicts: [ 'AppIconLegacy-Settings~ipad.png' ]
    'AppIcon-Settings@2x~ipad.png':
      size: 58
      conflicts: [ 'AppIconLegacy-Settings@2x~ipad.png' ]
    'AppIcon-Spotlight~ipad.png':
      size: 40
    'AppIcon-Spotlight@2x~ipad.png':
      size: 80
    'AppIcon~ipad.png':
      size: 76
    'AppIcon@2x~ipad.png':
      size: 152

  car:
    'AppIcon~car.png':
      size: 120

  watch:
    'AppIcon-NotificationCenter38mm@2x~watch.png':
      size: 29
      settingSize: '14.5'
      role: 'notificationCenter'
    'AppIcon-NotificationCenter42mm@2x~watch.png':
      size: 36
      role: 'notificationCenter'
    'AppIcon-38mm@2x~watch.png':
      size: 80
      role: 'appLauncher'
    'AppIcon-42mm@2x~watch.png':
      size: 88
      role: 'appLauncher'
    'AppIcon-QuickLook38mm@2x~watch.png':
      size: 172
      role: 'quickLook'
    'AppIcon-QuickLook42mm@2x~watch.png':
      size: 196
      role: 'quickLook'
    'AppIcon-Settings@2x~watch.png':
      size: 58
      role: 'companionSettings'
    'AppIcon-Settings@3x~watch.png':
      size: 88
      settingSize: '29.3'
      role: 'companionSettings'

  iPhoneLegacy:
    'AppIconLegacy-Small~iphone.png':
      size: 29
    'AppIconLegacy-Small@2x~iphone.png':
      size: 58
    'AppIconLegacy~iphone.png':
      size: 57
    'AppIconLegacy@2x~iphone.png':
      size: 114

  iPadLegacy:
    'AppIconLegacy-Settings~ipad.png':
      size: 29
    'AppIconLegacy-Settings@2x~ipad.png':
      size: 58
    'AppIconLegacy-Spotlight~ipad.png':
      size: 50
    'AppIconLegacy-Spotlight@2x~ipad.png':
      size: 100
    'AppIconLegacy~ipad.png':
      size: 72
    'AppIconLegacy@2x~ipad.png':
      size: 144

appIconList = []
_(appIconGroups).each (groupContents) ->
  _(groupContents).each (values, key) -> appIconList.push key

launchImageGroups = 
  iOS8Portrait:
    'Default-667h@2x~iphone.png':
      minimumSystemVersion: '8.0'
      width: 750
      height: 1334
    'Default-Portrait736h@3x~iphone.png':
      minimumSystemVersion: '8.0'
      width: 1242
      height: 2208

  iOS8Landscape: 'Default-Landscape736h@3x~iphone.png':
    minimumSystemVersion: '8.0'
    width: 2208
    height: 1242

  iPhonePortrait:
    'Default@2x~iphone.png':
      minimumSystemVersion: '7.0'
      width: 640
      height: 960
    'Default-568h@2x~iphone.png':
      minimumSystemVersion: '7.0'
      width: 640
      height: 1136

  iPadPortrait:
    'Default-Portrait~ipad.png':
      minimumSystemVersion: '7.0'
      width: 768
      height: 1024
    'Default-Portrait@2x~ipad.png':
      minimumSystemVersion: '7.0'
      width: 1536
      height: 2048

  iPadLandscape:
    'Default-Landscape~ipad.png':
      minimumSystemVersion: '7.0'
      width: 1024
      height: 768
    'Default-Landscape@2x~ipad.png':
      minimumSystemVersion: '7.0'
      width: 2048
      height: 1536

  watch:
    'Default-38mm@2x~watch.png':
      minimumSystemVersion: '8.0'
      width: 272
      height: 340
    'Default-42mm@2x~watch.png':
      minimumSystemVersion: '8.0'
      width: 312
      height: 390

  iPhoneLegacyPortrait:
    'DefaultLegacy~iphone.png':
      width: 320
      height: 480
    'DefaultLegacy@2x~iphone.png':
      width: 640
      height: 960
    'DefaultLegacy-568h@2x~iphone.png':
      width: 640
      height: 1136

  iPadLegacyPortrait:
    'DefaultLegacy-Portrait~ipad.png':
      width: 768
      height: 1024
    'DefaultLegacy-Portrait@2x~ipad.png':
      width: 1536
      height: 2048

  iPadLegacyLandscape:
    'DefaultLegacy-Landscape~ipad.png':
      width: 1024
      height: 768
    'DefaultLegacy-Landscape@2x~ipad.png':
      width: 2048
      height: 1536

launchImageList = []
_(launchImageGroups).each (groupContents) ->
  _(groupContents).each (values, key) -> launchImageList.push key

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
xcassets = false
verbose = false
minimumPhone = 2
maximumPhone = 3
minimumPad = 1
maximumPad = 2
minimumUniversal = 1
maximumUniversal = 3

contentsJSONForImage = (filenames, basename) ->
  contents = 
    images: []
    info:
      version: 1
      author: 'xcode'

  firstFilename = filenames[0]
  extension = path.extname firstFilename
  isDeviceSpecific = !! firstFilename.match(/~([a-z]+)/)
  
  contents.info['template-rendering-intent'] = 'original' if extension == '.jpg'
  possibleNames = []
  scaleSuffix = undefined
  if isDeviceSpecific
    scale = 1
    while scale <= 3
      scaleSuffix = if scale == 1 then '' else '@' + scale + 'x'
      possibleNames.push '' + basename + scaleSuffix + '~iphone' + extension
      scale++
    scale = 1
    while scale <= 2
      scaleSuffix = if scale == 1 then '' else '@' + scale + 'x'
      possibleNames.push '' + basename + scaleSuffix + '~ipad' + extension
      scale++
  else
    scale = 1
    while scale <= 3
      scaleSuffix = if scale == 1 then '' else '@' + scale + 'x'
      possibleNames.push '' + basename + scaleSuffix + extension
      scale++
  _(possibleNames).each (possibleName) ->
    idiom = possibleName.match(/~([a-z]+)/)
    idiom = if idiom then idiom[1] else 'universal'
    scale = possibleName.match(/@(\d+)x/)
    scale = if scale then '' + scale[1] + 'x' else '1x'
    imageInfo = 
      idiom: idiom
      scale: scale
    if _.contains filenames, possibleName
      imageInfo.filename = possibleName
    contents.images.push imageInfo
  JSON.stringify contents

contentsJSONForAppIcon = (filenames, directoryName) ->
  contents = 
    images: []
    info:
      version: 1
      author: 'xcode'
    properties: 'pre-rendered': true
  filteredAppIconList = resourceListWithRequiredGroups filenames, appIconGroups
  conflictSkipList = []
  _(filteredAppIconList).each (appIconName) ->
    appIconInfo = getAppIconInfo(appIconName)
    if appIconInfo and appIconInfo.conflicts
      merged = _.union [ appIconName ], appIconInfo.conflicts
      if _.intersection(filenames, merged).length == merged.length
        filenames = _.difference filenames, appIconInfo.conflicts
        _(appIconInfo.conflicts).each (appIconConflict) ->
          conflictSkipList.push appIconConflict
          fs.unlinkSync outputDirectory + directoryName + '/' + appIconConflict

  _(filteredAppIconList).each (appIconName) ->
    return if conflictSkipList.indexOf(appIconName) > -1
    appIconInfo = getAppIconInfo appIconName
    idiom = appIconName.match /~([a-z]+)/
    idiom = if idiom then idiom[1] else 'universal'
    scale = appIconName.match(/@(\d+)x/)
    scale = if scale then scale[1] else 1
    scaleSetting = '' + scale + 'x'

    if appIconInfo and appIconInfo.settingSize
      size = '' + appIconInfo.settingSize + 'x' + appIconInfo.settingSize
    else
      scaledSize = Math.round(appIconInfo.size / scale)
      size = '' + scaledSize + 'x' + scaledSize

    imageInfo = 
      size: size
      idiom: idiom
      scale: scaleSetting
    subtype = getImageSubtype(appIconName)
    
    imageInfo.subtype = subtype if subtype
    imageInfo.role = appIconInfo.role if appIconInfo and appIconInfo.role
    imageInfo.filename = appIconName if _.contains filenames, appIconName

    contents.images.push imageInfo
  JSON.stringify contents

contentsJSONForLaunchImage = (filenames, directoryName) ->
  contents = 
    images: []
    info:
      version: 1
      author: 'xcode'
  filteredLaunchImageList = resourceListWithRequiredGroups(filenames, launchImageGroups)
  _(filteredLaunchImageList).each (launchImageName) ->
    idiom = launchImageName.match /~([a-z]+)/
    idiom = if idiom then idiom[1] else 'universal'
    scale = launchImageName.match /@(\d+)x/
    scale = if scale then '' + scale[1] + 'x' else '1x'
    orientation = if /landscape/i.test(launchImageName) then 'landscape' else 'portrait'
    imageInfo = 
      extent: 'full-screen'
      idiom: idiom
      orientation: orientation
      scale: scale
    launchImageInfo = getLaunchImageInfo(launchImageName)
    
    imageInfo['minimum-system-version'] = launchImageInfo.minimumSystemVersion if launchImageInfo and launchImageInfo.minimumSystemVersion
    subtype = getImageSubtype(launchImageName)
    imageInfo.subtype = subtype if subtype
    imageInfo.filename = launchImageName if _.contains filenames, launchImageName
    contents.images.push imageInfo

  JSON.stringify contents

getAppIconInfo = (needle) ->
  for groupName of appIconGroups
    filenames = _.keys appIconGroups[groupName]
    return appIconGroups[groupName][ needle] if _.contains filenames, needle
  false

getLaunchImageInfo = (needle) ->
  for groupName of launchImageGroups
    filenames = _.keys(launchImageGroups[groupName])
    
    return launchImageGroups[groupName][needle] if _.contains filenames, needle
  false

getImageSubtype = (filename) ->
  heightSubtype = filename.match /(\d+)h/
  if heightSubtype
    number = parseInt heightSubtype[1]
    return 'retina4' if number == 568
    return number + 'h'
  watchSubtype = filename.match(/(\d+)mm/)
  if watchSubtype
    number = parseInt watchSubtype[1]
    return number + 'mm'
  false

resourceListWithRequiredGroups = (filenames, groupedList) ->
  requiredGroups = []
  for groupName of groupedList
    requiredGroups.push groupName if _.intersection(filenames, _.keys(groupedList[groupName])).length

  filteredGroups = _.pick groupedList, requiredGroups
  result = []
  _(filteredGroups).each (groupContents) ->
    _(groupContents).each (values, key) -> result.push key
  result

createContentsJSON = ->
  paths = walk.sync(outputDirectory)
  paths = _.map paths, (filepath) -> filepath.replace outputDirectory, ''
  assetDirectories = _.filter paths, (filepath) -> /\.appiconset$/.test(filepath) or /\.launchimage$/.test(filepath) or /\.imageset$/.test(filepath)

  _(assetDirectories).each (directory) ->
    basename = directory.split('/').pop()
    extension = path.extname basename
    basename = basename.slice 0, extension.length * -1
    directoryContents = _.filter paths, (filepath) -> filepath.indexOf(directory + '/') == 0
    directoryContents = _.map directoryContents, (filepath) -> filepath.replace directory + '/', ''
    directoryContents = _.filter directoryContents, (filename) ->
      return false if filename.slice(0, 1) == '.'
      return false if filename == 'Contents.json'
      true
    contents = '{}'
    contents = contentsJSONForAppIcon directoryContents, directory if /\.appiconset$/.test directory
    contents = contentsJSONForLaunchImage directoryContents, directory if /\.launchimage$/.test directory
    contents = contentsJSONForImage directoryContents, basename if /\.imageset$/.test directory
    fs.writeFileSync outputDirectory + directory + '/Contents.json', contents
    process.stdout.write 'Created Contents.json for ' + directory + '\n' if verbose

processImage = (task, cb) ->
  info = task.info
  device = task.device
  scale = task.scale
  name = '' + scale
  highestScale = info.devices[device].highestScale
  return cb() if scale > highestScale
  fs.ensureDirSync '' + outputDirectory + info.foldername
  highestScaleImagePath = inputDirectory + info.devices[device]['' + highestScale]
  image = im(highestScaleImagePath).out '-define', 'png:exclude-chunk=date'
  image.size (err, size) ->
    # unchangedOutputPath = ''
    imageWidth = size.width
    imageHeight = size.height
    scaleSuffix = if scale == 1 then '' else '@' + scale + 'x'
    deviceSuffix = if device == 'universal' then '' else '~' + device
    from = '' + inputDirectory + info.devices[device][name]
    outputPath = '' + info.id + scaleSuffix + deviceSuffix + info.extension

    if info.id.indexOf('AppIcon') == 0
      unchangedOutputPath = outputPath
      if !_.contains appIconList, outputPath
        iPhoneOutputPath = '' + info.id + scaleSuffix + '~iphone' + info.extension
        if _.contains appIconList, iPhoneOutputPath
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

    if info.id.indexOf('Default') == 0
      unchangedOutputPath = outputPath
      if !_.contains(launchImageList, outputPath)
        iPhoneOutputPath = '' + info.id + scaleSuffix + '~iphone' + info.extension
        if _.contains(launchImageList, iPhoneOutputPath)
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
      if info.id.indexOf('AppIcon') == 0
        outputPath = 'AppIcon.appiconset/' + info.id + scaleSuffix + deviceSuffix + info.extension
        fs.ensureDirSync outputDirectory + 'AppIcon.appiconset/'
      else if info.id.indexOf('Default') == 0
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
    i = 0
    len = pathSegments.length
    while i < len
      segment = pathSegments[i]
      return false if segment.slice(0, 1) == '_'
      i++
    true

  grouped = _.groupBy filtered, (filepath) ->
    extension = path.extname filepath
    namepath = filepath.slice 0, extension.length * -1
    normalized = namepath.replace(/@(\d+)x/, '').replace(/~([a-z]+)/, '')
    normalized

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
      
    _(paths).each (filepath) ->
      extension = path.extname filepath
      namepath = filepath.slice 0, extension.length * -1
      scaleMatch = namepath.match /@(\d+)x/
      scale = if scaleMatch then parseInt scaleMatch[1] else 1
      deviceMatch = namepath.match /~([a-z]+)/i
      device = if deviceMatch then deviceMatch[1].toLowerCase() else 'universal'
      if !_.has descriptor.devices, device
        descriptor.devices[device] = {}
      descriptor.devices[device][scale] = filepath

    for device of descriptor.devices
      paths = descriptor.devices[device]
      maxScale = _.max _.keys(paths), (key) -> parseInt key
      descriptor.devices[device].highestScale = parseInt maxScale
    if (_.has(descriptor.devices, 'iphone') or _.has(descriptor.devices, 'ipad')) and _.has(descriptor.devices, 'universal') and xcassets and !(identifier.indexOf('AppIcon') == 0 or identifier.indexOf('Default') == 0)
      delete descriptor.devices.universal
    imageDescriptors.push descriptor
  imageDescriptors

module.exports = (directory, options, globalOptions) ->
  verbose = globalOptions.verbose
  xcassets = options.xcassets
  allowedExtensions = if xcassets then xcassetsAllowedExtensions else directoryAllowedExtensions
  minimumPhone = options.minimumPhone
  maximumPhone = options.maximumPhone
  minimumPad = options.minimumPad
  maximumPad = options.maximumPad
  minimumUniversal = options.minimumUniversal
  maximumUniversal = options.maximumUniversal
  inputDirectory = directory
  outputDirectoryName = globalOptions.outputDirectoryName or 'Images'
  outputDirectoryName = outputDirectoryName + '.xcassets' if xcassets
  outputDirectory = path.join globalOptions.cwd, outputDirectoryName
  outputDirectory += '/' if outputDirectory.slice(-1) != '/'
  fs.removeSync outputDirectory if globalOptions.clean
  fs.ensureDirSync outputDirectory

  queue = async.queue processImage, 4
  queue.drain = -> createContentsJSON() if xcassets

  imageDescriptors = describeInputDirectory inputDirectory

  _(deviceTypes).each (device) ->
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
        minDensity = minimumUniversal
        maxDensity = maximumUniversal
        absoluteMinDensity = 1
        absoluteMaxDensity = 3

    _(imageDescriptors).each (descriptor) ->
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
          if scale == 'highestScale'
            scale++
            continue
          scale = parseInt scale
          if (scale < adjustedMinDensity or scale > adjustedMaxDensity) and scale >= absoluteMinDensity and scale <= absoluteMaxDensity
            queue.push
              info: descriptor
              device: device
              scale: scale
