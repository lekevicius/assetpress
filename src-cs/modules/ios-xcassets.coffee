fs = require 'fs-extra'
path = require 'path'

_ = require 'lodash'
walk = require 'walkdir'
pngparse = require 'pngparse'
im = require('gm').subClass imageMagick: true

iOSConstants = require './ios-constants'
util = require '../utilities'

AUTHOR = "assetpress"

outputDirectory = ''
options = {}
defaults =
  verbose: false
  
supportedModifiers = [ 'template', '9' ]

hasAnyModifier = (basename) ->
  return modifier for modifier in supportedModifiers when _.endsWith(basename, ".#{ modifier }")
  false

stringRemoveModifier = (string, modifier) -> string.replace ".#{ modifier }", ''

stringWithoutModifiers = (string) ->
  for modifier in supportedModifiers
    string = string.replace ".#{ modifier }", ''
  string

removeModifier = (modifier, filenames, directory, contents, basename) ->
  # Renaming files and directory itself
  directoryPath = path.resolve outputDirectory, directory
  for file in fs.readdirSync directoryPath
    # Do not rename Contents.json
    continue unless file.indexOf(".#{ modifier }") > 0
    fs.renameSync path.resolve(directoryPath, file), path.resolve(directoryPath, stringRemoveModifier(file, modifier))
  fs.renameSync directoryPath, stringRemoveModifier(directoryPath, modifier)
  # Updating variables
  filenames = _.map filenames, (filename) -> stringRemoveModifier filename, modifier
  directory = stringRemoveModifier directory, modifier
  basename = stringRemoveModifier basename, modifier
  return [ filenames, directory, contents, basename ]

runTemplateModifier = (filenames, directory, contents, basename, callback) ->
  contents.info['template-rendering-intent'] = 'template'
  completedModifierAction 'template', filenames, directory, contents, basename, callback
  
remove9Patches = (filesToCrop, filenames, directory, contents, basename, callback) ->
  if filesToCrop.length
    fileToCrop = filesToCrop.pop()
    scaledPatchInfo = fileToCrop.match /@(\d+)x/i
    imageScale = if scaledPatchInfo then parseInt(scaledPatchInfo[1]) else 1
    imagePath = path.resolve outputDirectory, directory, fileToCrop
    
    cropImage = im(imagePath)
    cropImage.size (err, size) ->
      cropImage
      .crop (size.width - 2 * imageScale), (size.height - 2 * imageScale), imageScale, imageScale
      .out '-define', 'png:exclude-chunk=tIME,tEXt,zTXt,date'
      .write imagePath, (err) ->
        process.stdout.write err + '\n' if err
        process.stdout.write "Cropped 9-patch image #{ imagePath }\n" if options.verbose
        remove9Patches filesToCrop, filenames, directory, contents, basename, callback
  else
    completedModifierAction '9', filenames, directory, contents, basename, callback

readPixelRow = (data, row, scale) ->
  alphas = []
  switch row
    when 'top'
      y = 0
      for x in [scale..(data.width - 1 - scale)] by scale
        offset = (y * data.width + x) * 4
        alphas.push data.data[ offset + 3 ]
    when 'left'
      x = 0
      for y in [scale..(data.height - 1 - scale)] by scale
        offset = (y * data.width + x) * 4
        alphas.push data.data[ offset + 3 ]
  
  groups = []
  currentGroup = [ 0, ( alphas[0] > 128 ) ]
  for alpha in alphas
    if ( alpha > 128 ) isnt currentGroup[1]
      groups.push _.clone(currentGroup)
      currentGroup = [ 0, ( alpha > 128 ) ]
    currentGroup[0] += 1
  groups.push _.clone(currentGroup)
  
  result = { startInset: 0, center: 0, endInset: 0 }
  # Patch with both insets off-on-off
  if groups.length is 3 and groups[0][1] is false and groups[1][1] is true and groups[2][1] is false
    result.startInset = groups[0][0]
    result.center = groups[1][0]
    result.endInset = groups[2][0]
  # Either off-on or on-off, one inset
  else if groups.length is 2
    if groups[0][1] is false and groups[1][1] is true
      result.startInset = groups[0][0]
      result.center = groups[1][0]
    else if groups[0][1] is true and groups[1][1] is false
      result.center = groups[0][0]
      result.endInset = groups[1][0]
    else return false
  # Everything on
  else if groups.length is 1 and groups[0][1] is true
    result.center = groups[0][0]
  # False return means either incorrectly drawn patch or empty patch, which implies no tiling
  else return false
  return result
      
getResizingObject = (data, scale) ->
  topRowInfo = readPixelRow data, 'top', scale
  leftRowInfo = readPixelRow data, 'left', scale
  
  if topRowInfo or leftRowInfo
    resizing = {
      mode: '',
      center: {
        mode: 'fill'
      },
      capInsets: {}
    }
    
    if topRowInfo and leftRowInfo
      resizing.mode = '9-part'
    else if topRowInfo
      resizing.mode = '3-part-horizontal'
    else
      resizing.mode = '3-part-vertical'
    
    if topRowInfo
      resizing.center.width = topRowInfo.center
      resizing.capInsets.left = topRowInfo.startInset
      resizing.capInsets.right = topRowInfo.endInset
    if leftRowInfo
      resizing.center.height = leftRowInfo.center
      resizing.capInsets.top = leftRowInfo.startInset
      resizing.capInsets.bottom = leftRowInfo.endInset
    
    return resizing
  else return false

run9PatchModifier = (filenames, directory, contents, basename, callback) ->
  scaledPatchInfo = filenames[0].match /@(\d+)x/i
  imageScale = if scaledPatchInfo then parseInt(scaledPatchInfo[1]) else 1
  imagePath = path.resolve(outputDirectory, directory, filenames[0])
  
  pngparse.parseFile imagePath, (err, data) ->
    process.stdout.write err if err
    resizingObject = getResizingObject data, imageScale
    contents['__additions'] = {}
    # FIXME: handle multiple additions (not relevant with current Xcode features)
    for filename in filenames
      filename = stringWithoutModifiers filename
      scaledPatchInfo = filename.match /@(\d+)x/i
      imageScale = if scaledPatchInfo then parseInt(scaledPatchInfo[1]) else 1
      
      scaledResizingObject = _.cloneDeep resizingObject
      scaledResizingObject.center.width *= imageScale if scaledResizingObject.center.width
      scaledResizingObject.center.height *= imageScale if scaledResizingObject.center.height
      scaledResizingObject.capInsets.top *= imageScale if scaledResizingObject.capInsets.top
      scaledResizingObject.capInsets.right *= imageScale if scaledResizingObject.capInsets.right
      scaledResizingObject.capInsets.bottom *= imageScale if scaledResizingObject.capInsets.bottom
      scaledResizingObject.capInsets.left *= imageScale if scaledResizingObject.capInsets.left
      
      contents['__additions'][filename] = { resizing: scaledResizingObject }
      
    filesToCrop = _.clone filenames
    remove9Patches filesToCrop, filenames, directory, contents, basename, callback
  
completedModifierAction = (modifier, filenames, directory, contents, basename, callback) ->
  [ filenames, directory, contents, basename ] = removeModifier modifier, filenames, directory, contents, basename
  if hasAnyModifier basename
    runModifierActions filenames, directory, contents, basename, callback
  else 
    completeContentsJSONForImage filenames, directory, contents, basename, callback

runModifierActions = (filenames, directory, contents, basename, callback) ->
  modifier = hasAnyModifier basename
  if modifier is 'template'
    runTemplateModifier filenames, directory, contents, basename, callback
  if modifier is '9'
    run9PatchModifier filenames, directory, contents, basename, callback

contentsJSONForImage = (filenames, directory, callback) ->
  # Initial contents
  contents = 
    images: []
    info:
      version: 1
      author: AUTHOR

  # Directory name here is logo.imageset
  directoryName = directory.split('/').pop()
  # Basename is logo
  basename = directoryName.slice 0, path.extname(directoryName).length * -1
  
  if hasAnyModifier basename
    runModifierActions filenames, directory, contents, basename, callback
  else 
    completeContentsJSONForImage filenames, directory, contents, basename, callback
  
completeContentsJSONForImage = (filenames, directory, contents, basename, callback) ->
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
    # additional details added
    if _.has contents['__additions'], possibleName
      imageInfo = _.assign imageInfo, contents['__additions'][possibleName]

    contents.images.push imageInfo

  delete contents['__additions']
  callback(null, contents, directory)

contentsJSONForAppIcon = (filenames, directory) ->
  # Initial contents
  contents = 
    images: []
    info:
      version: 1
      author: AUTHOR
    properties: 'pre-rendered': true
  # The difficulty with App Icons and Launch Images is that 
  # you need to include entire group even only one icon exists in that group.
  # This is the function of resourceListWithRequiredGroups()
  filteredAppIconList = iOSConstants.resourceListWithRequiredGroups filenames, iOSConstants.appIconGroups, 'AppIcon'

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
          fs.unlinkSync outputDirectory + directory + '/' + appIconConflict

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

  contents

contentsJSONForLaunchImage = (filenames, directory) ->
  # Initial contents
  contents = 
    images: []
    info:
      version: 1
      author: AUTHOR

  filteredLaunchImageList = iOSConstants.resourceListWithRequiredGroups filenames, iOSConstants.launchImageGroups, 'Default'

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

  contents

module.exports = (passedOutputDirectory, passedOptions, callback) ->
  outputDirectory = util.addTrailingSlash util.resolvePath(passedOutputDirectory)
  options = _.defaults passedOptions, defaults

  # Walk the output directory, getting a list of all files and directories
  paths = _.map walk.sync(outputDirectory), (filepath) -> filepath.replace outputDirectory, ''
  # Just the list of folders to describe
  assetDirectories = _.filter paths, (filepath) -> /\.appiconset$/.test(filepath) or /\.launchimage$/.test(filepath) or /\.imageset$/.test(filepath)

  for directory in assetDirectories
    # XCAssets directories may be nested
    # Extension is .imageset
    extension = path.extname directory

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
    # Sync solutions
    contents = contentsJSONForAppIcon directoryContents, directory if extension is '.appiconset'
    contents = contentsJSONForLaunchImage directoryContents, directory if extension is '.launchimage'
    if extension is '.appiconset' or extension is '.launchimage'
      # Write it and optionally log
      fs.writeFileSync path.join(outputDirectory, directory, 'Contents.json'), JSON.stringify(contents)
      process.stdout.write "Created Contents.json for #{ directory }\n" if options.verbose
    # Async
    if extension is '.imageset'
      contentsJSONForImage directoryContents, directory, (err, resultingContents, resultingDirectory) ->
        process.stdout.write "Error!\n" if err
        # Write it and optionally log
        fs.writeFileSync path.join(outputDirectory, resultingDirectory, 'Contents.json'), JSON.stringify(resultingContents)
        process.stdout.write "Created Contents.json for #{ resultingDirectory }\n" if options.verbose


    
  callback()
