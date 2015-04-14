fs = require 'fs-extra'
path = require 'path'

_ = require 'lodash'
im = require('gm').subClass imageMagick: true
async = require 'async'
tmp = require 'temporary'

androidConstants = require './android-constants'
util = require '../utilities'

defaults =
  ldpi: false
  xxxhdpi: false

inputDirectory = ''
outputDirectory = ''
temporaryDirectory = ''
temporaryPartsDirectory = ''
options = {}

processImage = (task, callback) ->
  filepath = task.path
  basename = path.basename filepath

  image = im filepath
  image.size (err, size) ->

    # File object with everything related to resizing
    file = 
      filepath: filepath
      basename: basename
      filetype: path.extname(filepath).slice(1)
      density: task.density
      scaleFactor: androidConstants.densities[ task.density ] / 4.0
      image: image
      width: size.width
      height: size.height

    # Process image in one of three ways:
    if file.basename.match /\.nodpi\./i
      # NoDPI images need to processed only once, so it does when density is mdpi
      # This is a hack, because no-dpi images will be called for every density.
      if file.density == 'mdpi' then processNoDpiImage file, callback else callback()
    else if file.basename.match /\.9(@(\d+)x)?\./i
      process9PatchImage file, callback
    else
      processStandardImage file, callback

createPatch = (file, side, callback) ->
  # createPatch chops off and resizes one of the 9-patch sides.
  # side can be top, bottom, left or right.
  # This function uses patchScaleFactor, set by process9PatchImage.

  # Setting cropWidth, cropHeight, resizeWidth, resizeHeight
  if side is 'top' or side is 'bottom'
    cropWidth = file.width - file.patchScaleFactor * 2
    cropHeight = 1
    resizeWidth = Math.round cropWidth * file.scaleFactor
    resizeHeight = 1
  if side is 'left' or side is 'right'
    cropWidth = 1
    cropHeight = file.height - file.patchScaleFactor * 2
    resizeWidth = 1
    resizeHeight = Math.round cropHeight * file.scaleFactor

  # Setting crop coordinates
  switch side
    when 'top'
      [ x, y ] = [ file.patchScaleFactor, file.patchScaleFactor - 1 ]
    when 'left'
      [ x, y ] = [ file.patchScaleFactor - 1, file.patchScaleFactor ]
    when 'right'
      [ x, y ] = [ (file.width - file.patchScaleFactor), file.patchScaleFactor ]
    when 'bottom'
      [ x, y ] = [ file.patchScaleFactor, (file.height - file.patchScaleFactor) ]
      
  file[ side + 'PatchPath' ] = temporaryPartsDirectory + file.density + '-' + file.basename + '-' + side + 'Patch.png'

  # Doing the crop and saving into parts directory
  im file.filepath
  .crop cropWidth, cropHeight, x, y
  # Patch slices can be either completely black or fully transparent.
  # Proper resizing is achieved by turning off anti-aliasing and using Point resize filter.
  .antialias false
  .filter 'Point'
  .resize resizeWidth, resizeHeight, '!'
  .write file[ side + 'PatchPath' ], (error) ->
    process.stdout.write error if error
    callback()

createPatchContent = (file, callback) ->
  # Content width is image width with both 9-patch sides removed.
  cropWidth = file.width - file.patchScaleFactor * 2
  cropHeight = file.height - file.patchScaleFactor * 2
  # Patch scale factor is >= 1, file.scaleFactor is <= 1
  file.patchContentWidth = Math.round cropWidth * file.scaleFactor
  file.patchContentHeight = Math.round cropHeight * file.scaleFactor
  
  file.contentPatchPath = temporaryPartsDirectory + file.density + '-' + file.basename + '-content.png'

  im file.filepath
  .crop cropWidth, cropHeight, file.patchScaleFactor, file.patchScaleFactor
  .filter androidConstants.resizeFilter
  .resize file.patchContentWidth, file.patchContentHeight
  .write file.contentPatchPath, (error) ->
    process.stdout.write error if error
    callback()

process9PatchImage = (file, callback) ->
	# Patch scale is in the filename: button.9@4x.png indicates that it's a 9-patch with 4px thick patches.
  scaledPatchInfo = file.basename.match /\.9@(\d+)x\./i
  if scaledPatchInfo
    file.patchScaleFactor = parseInt scaledPatchInfo[1]
    # Dropping the patch size indication for saving with correct name
    file.basename = file.basename.replace /\.9@(\d+)x\./i, '.9.'
  else
    # Possible user error: not knowing about patch scale indicator in the name
    file.patchScaleFactor = 1
    
  # One way to enforce xxxhdpi starting image size.
  # Measuring size of the content, regardless of patch scale.
  if (file.width - file.patchScaleFactor * 2) % 4 isnt 0 or (file.height - file.patchScaleFactor * 2) % 4 isnt 0
    process.stdout.write "WARNING: Image #{ file.basename } dimensions are not multiples of 4. Skipping.\n"
    callback()

  fileDestination = temporaryDirectory + 'drawable-' + file.density + '/' + file.basename
  
  # Patch is combined from 5 images: center content, and 4 side patches
  # All 5 are resized seperately to different files, and later combined into one image.
  createPatchContent file, ->
    createPatch file, 'left', -> createPatch file, 'right', ->
      createPatch file, 'top', -> createPatch file, 'bottom', ->
        # Creating empty, transparent image size of resized patch content + 1 pixel on each side.
        _composite = im(file.patchContentWidth + 2, file.patchContentHeight + 2, '#ffffff00').out('-define', 'png:exclude-chunk=date')
        # Drawing content...
        _composite.draw [ "image Over 1,1 0,0 \'#{ file.contentPatchPath }\'" ]
        # And 4 patches.
        _composite.draw [ "image Over 1,0 0,0 \'#{ file.topPatchPath }\'" ]
        _composite.draw [ "image Over 0,1 0,0 \'#{ file.leftPatchPath }\'" ]
        _composite.draw [ "image Over #{ file.patchContentWidth + 1 },1 0,0 \'#{ file.rightPatchPath }\'" ]
        _composite.draw [ "image Over 1,#{ file.patchContentHeight + 1 } 0,0 \'#{ file.bottomPatchPath }\'" ]
        # Saving to temporary results folder
        _composite.write fileDestination, (error) ->
          process.stdout.write error if error
          process.stdout.write "Saved #{ file.basename } in #{ file.density } density.\n" if options.verbose
          callback()

processStandardImage = (file, callback) ->
  # All images must be xxxhdpi
  if file.width % 4 isnt 0 or file.height % 4 isnt 0
    process.stdout.write "WARNING: Image #{ file.basename } dimensions are not multiples of 4. Skipping.\n"
    return callback()
    
  fileDestination = temporaryDirectory + 'drawable-' + file.density + '/' + file.basename

  file.image
  # ImageMagic adds png date chunk that makes otherwise-identical PNGs different to VCSes.
  .out '-define', 'png:exclude-chunk=date'
  .filter androidConstants.resizeFilter
  .resize Math.round(file.width * file.scaleFactor), Math.round(file.height * file.scaleFactor), '!'
  .write fileDestination, (error) ->
    process.stdout.write error if error
    process.stdout.write "Saved  #{ file.basename } in #{ file.density } density.\n" if options.verbose
    callback()

processNoDpiImage = (file, callback) ->
  # NoDPIs are rare enough to not create no-dpi folder initially.
  fs.ensureDirSync temporaryDirectory + 'drawable-nodpi'
  # AssetPress uses notation similar to 9-patches for NoDPI images: graphic.nodpi.png
  cleanBasename = file.basename.replace '.nodpi', ''
  # No resize needed (by definition)
  fs.copy file.filepath, temporaryDirectory + 'drawable-nodpi/' + cleanBasename, ->
    process.stdout.write "Saved nodpi image #{ file.basename }\n" if options.verbose
    callback()

module.exports = (passedInputDirectory, passedOutputDirectory = false, passedOptions = {}, callback = false) ->

  inputDirectory = util.addTrailingSlash util.resolvePath(passedInputDirectory)
  passedInputDirectory = passedOutputDirectory
  options = _.defaults passedOptions, defaults
  unless callback then callback = -> # noop

  outputDirectoryName = if passedOutputDirectory then util.removeTrailingSlash(passedOutputDirectory) else 'res'

  outputDirectoryBase = util.resolvePath inputDirectory, '..'
  outputDirectory = util.addTrailingSlash util.resolvePath(outputDirectoryBase, outputDirectoryName)

  # temporaryDirectory is for final output
  temporaryDirectoryObject = new tmp.Dir
  temporaryDirectory = util.addTrailingSlash temporaryDirectoryObject.path
  # temporaryPartsDirectory is for 9-patch parts
  temporaryPartsDirectoryObject = new tmp.Dir
  temporaryPartsDirectory = util.addTrailingSlash temporaryPartsDirectoryObject.path

  produceDensities = _.keys androidConstants.densities
  produceDensities = _.without(produceDensities, 'ldpi') unless options.ldpi
  produceDensities = _.without(produceDensities, 'xxxhdpi') unless options.xxxhdpi
  # Creating all density subfolders beforehand:
  fs.ensureDirSync path.resolve(temporaryDirectory, "drawable-#{ density }") for density in produceDensities

  queue = async.queue processImage, 2
  queue.drain = ->
    # These are the final actions: moving results from temporary folder to final output
    for density in produceDensities
      util.move path.resolve(temporaryDirectory, "drawable-#{ density }"), path.resolve(outputDirectory, "drawable-#{ density }"), options.clean
    # And removing temporary folder.
    fs.removeSync temporaryPartsDirectory
    fs.removeSync temporaryDirectory
    callback()

  # Android resources can't be in subfolders, so everything is much simpler
  for file in fs.readdirSync(inputDirectory)
    # Skip hidden or underscored files
    continue if file.slice(0, 1) is '.' or file.slice(0, 1) is '_'

    # Skip folders and warn
    unless fs.lstatSync( path.resolve(inputDirectory, file) ).isFile()
      process.stdout.write "Android does not support nested resources. Skipping #{ file }.\n" # if options.verbose
      continue

    # Skip unsupported formats
    unless _.contains androidConstants.allowedExtensions, path.extname(file)
      process.stdout.write "The format of #{ file }  is unsupported. Skipping.\n" # if options.verbose
      continue

    # Add images to the queue
    for density in produceDensities
      queue.push
        path: path.join inputDirectory, file
        density: density
        
      
