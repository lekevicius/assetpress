fs = require 'fs-extra'
path = require 'path'
_ = require 'lodash'
walk = require 'walkdir'

outputDirectory = ''
verbose = false

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
appIconList.push iconName for iconName of groupContents for groupName, groupContents of appIconGroups
module.exports.appIconList = appIconList

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
launchImageList.push launchImageName for launchImageName of groupContents for groupName, groupContents of launchImageGroups
module.exports.launchImageList = launchImageList

contentsJSONForImage = (filenames, basename) ->
  contents = 
    images: []
    info:
      version: 1
      author: 'xcode'

  firstFilename = filenames[0]
  extension = path.extname firstFilename
  isDeviceSpecific = !! firstFilename.match /~([a-z]+)/
  
  contents.info['template-rendering-intent'] = 'original' if extension is '.jpg'
  possibleNames = []

  if isDeviceSpecific
    scale = 1
    while scale <= 3
      scaleSuffix = if scale is 1 then '' else '@' + scale + 'x'
      possibleNames.push basename + scaleSuffix + '~iphone' + extension
      scale++
    scale = 1
    while scale <= 2
      scaleSuffix = if scale is 1 then '' else '@' + scale + 'x'
      possibleNames.push basename + scaleSuffix + '~ipad' + extension
      scale++
  else
    scale = 1
    while scale <= 3
      scaleSuffix = if scale is 1 then '' else '@' + scale + 'x'
      possibleNames.push basename + scaleSuffix + extension
      scale++

  for possibleName in possibleNames
    idiom = possibleName.match /~([a-z]+)/
    idiom = if idiom then idiom[1] else 'universal'
    scale = possibleName.match /@(\d+)x/
    scale = if scale then scale[1] + 'x' else '1x'
    imageInfo = 
      idiom: idiom
      scale: scale
    imageInfo.filename = possibleName if _.contains filenames, possibleName
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
  for appIconName in filteredAppIconList
    appIconInfo = getAppIconInfo appIconName
    if appIconInfo and appIconInfo.conflicts
      merged = _.union [ appIconName ], appIconInfo.conflicts
      if _.intersection(filenames, merged).length is merged.length
        filenames = _.difference filenames, appIconInfo.conflicts
        for appIconConflict in appIconInfo.conflicts
          conflictSkipList.push appIconConflict
          fs.unlinkSync outputDirectory + directoryName + '/' + appIconConflict

  for appIconName in filteredAppIconList
    continue if conflictSkipList.indexOf(appIconName) > -1
    appIconInfo = getAppIconInfo appIconName
    idiom = appIconName.match /~([a-z]+)/
    idiom = if idiom then idiom[1] else 'universal'
    scale = appIconName.match /@(\d+)x/
    scale = if scale then scale[1] else 1
    scaleSetting = scale + 'x'

    if appIconInfo and appIconInfo.settingSize
      size = appIconInfo.settingSize + 'x' + appIconInfo.settingSize
    else
      scaledSize = Math.round appIconInfo.size / scale
      size = scaledSize + 'x' + scaledSize

    imageInfo = 
      size: size
      idiom: idiom
      scale: scaleSetting
    subtype = getImageSubtype appIconName
    
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
  filteredLaunchImageList = resourceListWithRequiredGroups filenames, launchImageGroups
  for launchImageName in filteredLaunchImageList
    idiom = launchImageName.match /~([a-z]+)/
    idiom = if idiom then idiom[1] else 'universal'
    scale = launchImageName.match /@(\d+)x/
    scale = if scale then scale[1] + 'x' else '1x'
    orientation = if /landscape/i.test(launchImageName) then 'landscape' else 'portrait'
    imageInfo = 
      extent: 'full-screen'
      idiom: idiom
      orientation: orientation
      scale: scale
    launchImageInfo = getLaunchImageInfo launchImageName
    
    imageInfo['minimum-system-version'] = launchImageInfo.minimumSystemVersion if launchImageInfo and launchImageInfo.minimumSystemVersion
    subtype = getImageSubtype(launchImageName)
    imageInfo.subtype = subtype if subtype
    imageInfo.filename = launchImageName if _.contains filenames, launchImageName
    contents.images.push imageInfo

  JSON.stringify contents

getAppIconInfo = (needle) ->
  for groupName of appIconGroups
    filenames = _.keys appIconGroups[groupName]
    return appIconGroups[groupName][needle] if _.contains filenames, needle
  false

getLaunchImageInfo = (needle) ->
  for groupName of launchImageGroups
    filenames = _.keys launchImageGroups[groupName]
    return launchImageGroups[groupName][needle] if _.contains filenames, needle
  false

getImageSubtype = (filename) ->
  heightSubtype = filename.match /(\d+)h/
  if heightSubtype
    number = parseInt heightSubtype[1]
    return 'retina4' if number is 568
    return number + 'h'
  watchSubtype = filename.match(/(\d+)mm/)
  if watchSubtype
    number = parseInt watchSubtype[1]
    return number + 'mm'
  false

resourceListWithRequiredGroups = (filenames, groupedList) ->
  requiredGroups = ( groupName for groupName of groupedList when _.intersection(filenames, _.keys(groupedList[groupName])).length )
  filteredGroups = _.pick groupedList, requiredGroups
  result = []
  result.push key for key, value of groupContents for groupName, groupContents of filteredGroups
  result

module.exports.createContentsJSON = (describedDirectory, globalOptions) ->
  outputDirectory = describedDirectory
  verbose = globalOptions.verbose
  paths = walk.sync outputDirectory
  paths = _.map paths, (filepath) -> filepath.replace outputDirectory, ''
  assetDirectories = _.filter paths, (filepath) -> /\.appiconset$/.test(filepath) or /\.launchimage$/.test(filepath) or /\.imageset$/.test(filepath)

  for directory in assetDirectories
    basename = directory.split('/').pop()
    extension = path.extname basename
    basename = basename.slice 0, extension.length * -1
    directoryContents = _.filter paths, (filepath) -> filepath.indexOf(directory + '/') == 0
    directoryContents = _.map directoryContents, (filepath) -> filepath.replace directory + '/', ''
    directoryContents = _.filter directoryContents, (filename) ->
      return false if filename.slice(0, 1) is '.'
      return false if filename is 'Contents.json'
      true
    contents = '{}'
    contents = contentsJSONForAppIcon directoryContents, directory if /\.appiconset$/.test directory
    contents = contentsJSONForLaunchImage directoryContents, directory if /\.launchimage$/.test directory
    contents = contentsJSONForImage directoryContents, basename if /\.imageset$/.test directory
    fs.writeFileSync outputDirectory + directory + '/Contents.json', contents
    process.stdout.write 'Created Contents.json for ' + directory + '\n' if verbose
