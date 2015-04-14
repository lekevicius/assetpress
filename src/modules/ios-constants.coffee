_ = require 'lodash'

# Box is not perfect, but the best resizing algorithm.
module.exports.resizeFilter = 'Box'

# Resizing exceptions
module.exports.scalerExceptions = 
  'Default-Landscape736h': minDensity: 3
  'Default-Portrait736h': minDensity: 3

# All device types (~indicators)
module.exports.deviceTypes = [
  'universal'
  'iphone'
  'ipad'
  'car'
  'watch'
]

# Normally iOS supports all image formats
module.exports.directoryAllowedExtensions = [
  '.png'
  '.jpg'
  '.jpeg'
  '.gif'
]
# Gif support in XCassets has not been properly tested
module.exports.xcassetsAllowedExtensions = [
  '.png'
  '.jpg'
  '.jpeg'
]

# Definitions of all App Icons as of Xcode 6.3
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
      conflicts: [ 'AppIcon-Legacy-Small@2x~iphone.png' ]
    'AppIcon-Spotlight@2x~iphone.png':
      size: 80
    'AppIcon@2x~iphone.png':
      size: 120

  iPad:
    'AppIcon-Settings~ipad.png':
      size: 29
      conflicts: [ 'AppIcon-Legacy-Settings~ipad.png' ]
    'AppIcon-Settings@2x~ipad.png':
      size: 58
      conflicts: [ 'AppIcon-Legacy-Settings@2x~ipad.png' ]
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

    'AppIcon-NotificationCenter-38mm@2x~watch.png':
      size: 48
      role: 'notificationCenter'
    'AppIcon-NotificationCenter-42mm@2x~watch.png':
      size: 55
      settingSize: '27.5'
      role: 'notificationCenter'
    'AppIcon@2x~watch.png':
      size: 80
      role: 'appLauncher'
      settingSubtype: '38mm'
    'AppIcon-LongLook-42mm@2x~watch.png':
      size: 88
      role: 'longLook'
    'AppIcon-ShortLook-38mm@2x~watch.png':
      size: 172
      role: 'quickLook'
    'AppIcon-ShortLook-42mm@2x~watch.png':
      size: 196
      role: 'quickLook'
    'AppIcon-CompanionSettings@2x~watch.png':
      size: 58
      role: 'companionSettings'
    'AppIcon-CompanionSettings@3x~watch.png':
      size: 87
      role: 'companionSettings'

  iPhoneLegacy:
    'AppIcon-Legacy-Small~iphone.png':
      size: 29
    'AppIcon-Legacy-Small@2x~iphone.png':
      size: 58
    'AppIcon-Legacy~iphone.png':
      size: 57
    'AppIcon-Legacy@2x~iphone.png':
      size: 114

  iPadLegacy:
    'AppIcon-Legacy-Settings~ipad.png':
      size: 29
    'AppIcon-Legacy-Settings@2x~ipad.png':
      size: 58
    'AppIcon-Legacy-Spotlight~ipad.png':
      size: 50
    'AppIcon-Legacy-Spotlight@2x~ipad.png':
      size: 100
    'AppIcon-Legacy~ipad.png':
      size: 72
    'AppIcon-Legacy@2x~ipad.png':
      size: 144

# Simple list of all App Icon names
appIconList = []
appIconList.push iconName for iconName of groupContents for groupName, groupContents of appIconGroups

module.exports.appIconGroups = appIconGroups
module.exports.appIconList = appIconList

# Definitions of all Launch Images as of Xcode 6.3
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
    'Default-Legacy~iphone.png':
      width: 320
      height: 480
    'Default-Legacy@2x~iphone.png':
      width: 640
      height: 960
    'Default-Legacy-568h@2x~iphone.png':
      width: 640
      height: 1136

  iPadLegacyPortrait:
    'Default-Legacy-Portrait~ipad.png':
      width: 768
      height: 1024
    'Default-Legacy-Portrait@2x~ipad.png':
      width: 1536
      height: 2048

  iPadLegacyLandscape:
    'Default-Legacy-Landscape~ipad.png':
      width: 1024
      height: 768
    'Default-Legacy-Landscape@2x~ipad.png':
      width: 2048
      height: 1536

# Simple list of all Launch Image names
launchImageList = []
launchImageList.push launchImageName for launchImageName of groupContents for groupName, groupContents of launchImageGroups

module.exports.launchImageGroups = launchImageGroups
module.exports.launchImageList = launchImageList


module.exports.getDensityLimits = (device, options) ->
  switch device
    when 'iphone'
      minDensity = options.minimumPhone
      maxDensity = options.maximumPhone
      absoluteMinDensity = 1
      absoluteMaxDensity = 3
    when 'ipad'
      minDensity = options.minimumPad
      maxDensity = options.maximumPad
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
      minDensity = options.minimum
      maxDensity = options.maximum
      absoluteMinDensity = 1
      absoluteMaxDensity = 3
  # Returning 4 needed numbers.
  [ minDensity, maxDensity, absoluteMinDensity, absoluteMaxDensity ]

# Made to allow multiple AppIcons, such as AppIconBeta
module.exports.bareFormat = (name, startingWith) ->
  nameRoot = name.split(/-|~|@/)[0]
  nameRootSuffix = nameRoot.substr(startingWith.length) # AppIcon
  specifier = name.substr(startingWith.length + nameRootSuffix.length)
  barename = startingWith + specifier
  barename

# Given a filename, returns object describing that icon
module.exports.getAppIconInfo = (needle) ->
  bareNeedle = module.exports.bareFormat needle, 'AppIcon'
  for groupName of appIconGroups
    filenames = _.keys appIconGroups[groupName]
    return appIconGroups[groupName][bareNeedle] if _.contains filenames, bareNeedle
  false

# Given a filename, returns object describing that launch image
module.exports.getLaunchImageInfo = (needle) ->
  for groupName of launchImageGroups
    filenames = _.keys launchImageGroups[groupName]
    return launchImageGroups[groupName][needle] if _.contains filenames, needle
  false

# Different icons and launch images need different subtypes,
# this function tries to handle them all.
module.exports.getImageSubtype = (filename) ->
  # Some icons are better off without subtype in their name
  iconInfo = module.exports.getAppIconInfo filename
  if iconInfo and iconInfo.settingSubtype
    return iconInfo.settingSubtype
    
  # Launch images have height subtype, for instance 667h
  heightSubtype = filename.match /(\d+)h/
  if heightSubtype
    number = parseInt heightSubtype[1]
    # Exception is iPhone 5 size, that has 'retina4' subtype.
    # Xcode format is a wonderful study of legacy notations.
    return 'retina4' if number is 568
    return number + 'h'
    
  # Watch resources have mm subtypes.
  watchSubtype = filename.match(/(\d+)mm/)
  if watchSubtype
    number = parseInt watchSubtype[1]
    return number + 'mm'
  false

# Why this function is needed is described in iosXCAssets file, in app icon describer.
# It tries to find which icon groups are needed, given the filenames.
# Icon groups correspond to checkboxes in Xcode.
module.exports.resourceListWithRequiredGroups = (filenames, groupedList, startingWith) ->
  firstFilename = filenames[0]
  nameRoot = firstFilename.split(/-|~|@/)[0]
  nameRootSuffix = nameRoot.substr(startingWith.length)

  bareFilenames = _.map filenames, (name) -> module.exports.bareFormat name, startingWith
  requiredGroups = ( groupName for groupName of groupedList when _.intersection(bareFilenames, _.keys(groupedList[groupName])).length )
  filteredGroups = _.pick groupedList, requiredGroups
  result = []
  for groupName, groupContents of filteredGroups
    for key, value of groupContents
      specifier = key.substr(startingWith.length)
      keyWithReattachedSuffix = startingWith + nameRootSuffix + specifier
      result.push keyWithReattachedSuffix
  result
