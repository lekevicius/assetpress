fs = require 'fs-extra'
path = require 'path'

_ = require 'lodash'
walk = require 'walkdir'

iOSConstants = require './ios-constants'
util = require '../utilities'

outputDirectory = ''
defaults =
  verbose: false

contentsJSONForImage = (filenames, basename) ->
  # Initial contents
  contents = 
    images: []
    info:
      version: 1
      author: 'xcode'

  # Grab first filename
  firstFilename = filenames[0]
  # Because Xcode does not support both universal and device-specific resources, we can check the first file
  isDeviceSpecific = !! firstFilename.match /~([a-z]+)/

  extension = path.extname firstFilename
  # For JPGs it is (was?) recommended to set 'template-rendering-intent' to 'original'
  contents.info['template-rendering-intent'] = 'original' if extension is '.jpg'
  
  # A very important nuance of XCAssets Contents.json is that it lists all possible icons,
  # and some of them are simply listed without 'filename' key.
  # So we need to construct a list of all possible names, and later check if file exists.
  possibleNames = []

  if isDeviceSpecific
    # iPhone assets go icon~iphone.png, icon@2x~iphone.png, icon@3x~iphone.png
    scale = 1
    while scale <= 3
      scaleSuffix = if scale is 1 then '' else "@#{ scale }x"
      possibleNames.push basename + scaleSuffix + '~iphone' + extension
      scale++
    # iPad assets go icon~ipad.png, icon@2x~ipad.png
    scale = 1
    while scale <= 2
      scaleSuffix = if scale is 1 then '' else "@#{ scale }x"
      possibleNames.push basename + scaleSuffix + '~ipad' + extension
      scale++
  else
    # Universal assets go icon.png, icon@2x.png, icon@3x.png
    scale = 1
    while scale <= 3
      scaleSuffix = if scale is 1 then '' else "@#{ scale }x"
      possibleNames.push basename + scaleSuffix + extension
      scale++

  # Fill contents with all the fields
  for possibleName in possibleNames
    # idiom: iphone, ipad, universal
    idiom = possibleName.match /~([a-z]+)/
    idiom = if idiom then idiom[1] else 'universal'
    # scale: 1x, 2x, 3x
    scale = possibleName.match /@(\d+)x/
    scale = if scale then scale[1] + 'x' else '1x'
    imageInfo = 
      idiom: idiom
      scale: scale
    # filename field only added if file actually exists
    imageInfo.filename = possibleName if _.contains filenames, possibleName

    contents.images.push imageInfo

  JSON.stringify contents

contentsJSONForAppIcon = (filenames, directoryName) ->
  # Initial contents
  contents = 
    images: []
    info:
      version: 1
      author: 'xcode'
    properties: 'pre-rendered': true
  # The difficulty with App Icons and Launch Images is that 
  # you need to include entire group even only one icon exists in that group.
  # This is the function of resourceListWithRequiredGroups()
  filteredAppIconList = iOSConstants.resourceListWithRequiredGroups filenames, appIconGroups, 'AppIcon'

  # There are also conflicts related to iOS 6 / iOS 7 icons.
  # AppIcon-Settings@2x~iphone.png can be different for iOS 6 or iOS 7, and there is only one slot.
  # If both exist, iOS 7 takes precedence, and iOS 6 icon is deleted.
  conflictSkipList = []
  for appIconName in filteredAppIconList
    appIconInfo = iOSConstants.getAppIconInfo appIconName
    if appIconInfo and appIconInfo.conflicts
      # appIconName might be AppIcon-Settings@2x~iphone.png
      # appIconInfo.conflicts might be [ 'AppIcon-Legacy-Small@2x~iphone.png' ]
      # merged is both in one array.
      merged = _.union [ appIconName ], appIconInfo.conflicts
      # Intersection of filenames and and merged can be 
      # either 1 (no conflicts) or more (if there are conflicts)
      if _.intersection(filenames, merged).length > 1
        # If there exists at least one conflict, remove all conflicting icons
        # from everywhere filenames, filesystem and add to special skip-list.
        filenames = _.difference filenames, appIconInfo.conflicts
        for appIconConflict in appIconInfo.conflicts
          conflictSkipList.push appIconConflict
          fs.unlinkSync outputDirectory + directoryName + '/' + appIconConflict

  for appIconName in filteredAppIconList

    # conflictSkipList needs to be set up beforehand to skip all conflicts.
    continue if conflictSkipList.indexOf(appIconName) > -1

    appIconInfo = iOSConstants.getAppIconInfo appIconName

    idiom = appIconName.match /~([a-z]+)/
    idiom = if idiom then idiom[1] else 'universal'

    scale = appIconName.match /@(\d+)x/
    scale = if scale then scale[1] else 1

    if appIconInfo and appIconInfo.settingSize
      # Some icons need to have really weird sizes set in their JSON
      # SettingSize handles these exceptions.
      size = appIconInfo.settingSize + 'x' + appIconInfo.settingSize
    else
      # If icon is not an exception, it's easy to calculate size.
      scaledSize = Math.round appIconInfo.size / scale
      size = scaledSize + 'x' + scaledSize

    imageInfo = 
      size: size
      idiom: idiom
      scale: scale + 'x'

    imageInfo.role = appIconInfo.role if appIconInfo and appIconInfo.role

    subtype = iOSConstants.getImageSubtype appIconName
    imageInfo.subtype = subtype if subtype

    imageInfo.filename = appIconName if _.contains filenames, appIconName

    contents.images.push imageInfo

  JSON.stringify contents

contentsJSONForLaunchImage = (filenames, directoryName) ->
  # Initial contents
  contents = 
    images: []
    info:
      version: 1
      author: 'xcode'

  filteredLaunchImageList = iOSConstants.resourceListWithRequiredGroups filenames, launchImageGroups, 'Default'

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

    launchImageInfo = iOSConstants.getLaunchImageInfo launchImageName
    if launchImageInfo and launchImageInfo.minimumSystemVersion
      imageInfo['minimum-system-version'] = launchImageInfo.minimumSystemVersion

    subtype = iOSConstants.getImageSubtype(launchImageName)
    imageInfo.subtype = subtype if subtype

    imageInfo.filename = launchImageName if _.contains filenames, launchImageName

    contents.images.push imageInfo

  JSON.stringify contents

module.exports = (passedOutputDirectory, passedOptions, callback) ->
  outputDirectory = util.addTrailingSlash util.resolvePath(passedOutputDirectory)
  options = _.defaults passedOptions, defaults

  # Walk the output directory, getting a list of all files and directories
  paths = _.map walk.sync(outputDirectory), (filepath) -> filepath.replace outputDirectory, ''
  # Just the list of folders to describe
  assetDirectories = _.filter paths, (filepath) -> /\.appiconset$/.test(filepath) or /\.launchimage$/.test(filepath) or /\.imageset$/.test(filepath)

  for directory in assetDirectories
    # XCAssets directories may be nested
    # Here directory might be icons/logo.imageset
    # Directory name here is logo.imageset
    directoryName = directory.split('/').pop()
    # Extension is imageset
    extension = path.extname directoryName
    # Finally, basename is logo
    basename = directoryName.slice 0, extension.length * -1

    # Instead of reading the filesystem again, we get files from previously-built paths
    directoryContents = _(paths)
    # Only files in this directory
    .filter (filepath) -> filepath.indexOf(directory + '/') == 0
    # Relative to it
    .map (filepath) -> filepath.replace directory + '/', ''
    # Don't include existing Contents.json or hidden files
    .filter (filename) -> ( filename.slice(0, 1) isnt '.' and filename isnt 'Contents.json'  )
    .value()

    # Contents is JSON string
    contents = '{}'
    contents = contentsJSONForAppIcon directoryContents, directory if extension is 'appiconset'
    contents = contentsJSONForLaunchImage directoryContents, directory if extension is 'launchimage'
    contents = contentsJSONForImage directoryContents, basename if extension is 'imageset'

    # Write it and optionally log
    fs.writeFileSync outputDirectory + directory + '/Contents.json', contents
    process.stdout.write "Created Contents.json for #{ directory }\n" if options.verbose
    
  callback()
