im = require('gm').subClass imageMagick: true
fs = require 'fs-extra'
path = require 'path'
_ = require 'lodash'
async = require 'async'
tmp = require 'temporary'

densities = 
  ldpi: 0.75
  mdpi: 1
  hdpi: 1.5
  xhdpi: 2
  xxhdpi: 3
  xxxhdpi: 4

allowedExtensions = [
  '.png'
  '.jpg'
  '.jpeg'
  '.gif'
]

resizeFilter = 'Box'
temporaryDirectory = ''
outputDirectory = ''
verbose = false

processImage = (task, cb) ->
  filepath = task.path
  basename = path.basename filepath
  image = im filepath
  image.size (err, size) ->
    file = 
      filepath: filepath
      basename: basename
      filetype: path.extname(filepath).slice(1)
      density: task.density
      scaleFactor: densities[ task.density ] / 4.0
      image: image
      width: size.width
      height: size.height
    if file.basename.match /\.nodpi\./i
      if file.density == 'mdpi'
        processNoDpiImage file, cb
      else
        cb()
    else if file.basename.match /\.9(@(\d+)x)?\./i
      process9PatchImage file, cb
    else
      processStandardImage file, cb

createPatch = (side, file, cb) ->
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

  switch side
    when 'top'
      [ x, y ] = [ file.patchScaleFactor, file.pixelShift ]
    when 'left'
      [ x, y ] = [ file.pixelShift, file.patchScaleFactor ]
    when 'right'
      [ x, y ] = [ (file.width - file.patchScaleFactor), file.patchScaleFactor ]
    when 'bottom'
      [ x, y ] = [ file.patchScaleFactor, (file.height - file.patchScaleFactor) ]

  im file.filepath
  .crop cropWidth, cropHeight, x, y
  .antialias false
  .filter 'Point'
  .resize resizeWidth, resizeHeight, '!'
  .write temporaryDirectory + file.density + '-' + file.basename + '-' + side + 'Patch.png', (err) -> cb()

createPatchContent = (file, cb) ->
  cropWidth = file.width - file.patchScaleFactor * 2
  cropHeight = file.height - file.patchScaleFactor * 2
  file.patchContentWidth = Math.round cropWidth * file.scaleFactor
  file.patchContentHeight = Math.round cropHeight * file.scaleFactor

  im file.filepath
  .crop cropWidth, cropHeight, file.patchScaleFactor, file.patchScaleFactor
  .filter resizeFilter
  .resize file.patchContentWidth, file.patchContentHeight
  .write temporaryDirectory + file.density + '-' + file.basename + '-content.png', (err) -> cb()

process9PatchImage = (file, cb) ->
  scaledPatchInfo = file.basename.match /\.9@(\d+)x\./i
  if scaledPatchInfo
    file.patchScaleFactor = parseInt scaledPatchInfo[1]
    file.basename = file.basename.replace /\.9@(\d+)x\./i, '.9.'
  else
    file.patchScaleFactor = 1

  to = outputDirectory + 'drawable-' + file.density + '/' + file.basename
  file.pixelShift = file.patchScaleFactor - 1
  if (file.width - file.patchScaleFactor * 2) % 4 != 0 or (file.height - file.patchScaleFactor * 2) % 4 != 0
    return process.stdout.write('Image ' + file.basename + ' dimensions are not multiples of 4. Skipping.\n')

  createPatchContent file, ->
    createPatch 'left', file, -> createPatch 'right', file, ->
      createPatch 'top', file, -> createPatch 'bottom', file, ->
        _composite = im(file.patchContentWidth + 2, file.patchContentHeight + 2, '#ffffff00').out('-define', 'png:exclude-chunk=date')
        _composite.draw [ 'image Over 1,1 0,0 \'' + temporaryDirectory + file.density + '-' + file.basename + '-content.png\'' ]
        _composite.draw [ 'image Over 1,0 0,0 \'' + temporaryDirectory + file.density + '-' + file.basename + '-topPatch.png\'' ]
        _composite.draw [ 'image Over 0,1 0,0 \'' + temporaryDirectory + file.density + '-' + file.basename + '-leftPatch.png\'' ]
        _composite.draw [ 'image Over ' + (file.patchContentWidth + 1) + ',1 0,0 \'' + temporaryDirectory + file.density + '-' + file.basename + '-rightPatch.png\'' ]
        _composite.draw [ 'image Over 1,' + (file.patchContentHeight + 1) + ' 0,0 \'' + temporaryDirectory + file.density + '-' + file.basename + '-bottomPatch.png\'' ]
        _composite.write to, (err) ->
          console.log err if err
          process.stdout.write 'Saved ' + file.basename + ' in ' + file.density + ' density\n' if verbose
          cb()

processStandardImage = (file, cb) ->
  if file.width % 4 != 0 or file.height % 4 != 0
    return process.stdout.write('Image ' + file.basename + ' dimensions are not multiples of 4. Skipping.\n')
  to = outputDirectory + 'drawable-' + file.density + '/' + file.basename

  file.image
  .out '-define', 'png:exclude-chunk=date'
  .filter resizeFilter
  .resize Math.round(file.width * file.scaleFactor), Math.round(file.height * file.scaleFactor), '!'
  .write to, (err) ->
    process.stdout.write 'Saved ' + file.basename + ' in ' + file.density + ' density\n' if verbose
    cb()

processNoDpiImage = (file, cb) ->
  fs.ensureDirSync outputDirectory + 'drawable-nodpi'
  cleanBasename = file.basename.replace '.nodpi', ''
  fs.copy file.filepath, outputDirectory + 'drawable-nodpi/' + cleanBasename, ->
    process.stdout.write 'Saved nodpi image: ' + file.basename + '\n' if verbose
    cb()

module.exports = (directory, options, globalOptions) ->
  produceDensities = _.keys densities
  produceDensities = _.without(produceDensities, 'ldpi') if !options.ldpi
  produceDensities = _.without(produceDensities, 'xxxhdpi') if !options.xxxhdpi
  temporaryDirectoryObject = new tmp.Dir
  temporaryDirectory = temporaryDirectoryObject.path
  temporaryDirectory += '/' if temporaryDirectory.slice(-1) isnt '/'
  outputDirectoryName = globalOptions.outputDirectoryName or 'res'
  outputDirectory = path.join globalOptions.cwd, outputDirectoryName
  outputDirectory += '/' if outputDirectory.slice(-1) isnt '/'
  verbose = globalOptions.verbose
  fs.removeSync outputDirectory if globalOptions.clean and fs.existsSync(outputDirectory)
  fs.ensureDirSync outputDirectory
  fs.ensureDirSync outputDirectory + 'drawable-' + density for density in produceDensities

  queue = async.queue processImage, 2
  queue.drain = -> fs.removeSync temporaryDirectory

  for file in fs.readdirSync directory
    return if file.slice(0, 1) is '.'
    return if file.slice(0, 1) is '_'

    path_string = path.join directory, file
    extension = path.extname path_string

    if fs.lstatSync(path_string).isFile()
      if _.contains allowedExtensions, extension
        for density in produceDensities
          queue.push
            path: path_string
            density: density
      else
        process.stdout.write 'The format of ' + file + ' is unsupported. Skipping.\n' if verbose
    else
      process.stdout.write 'Android does not support nested resources. Skipping ' + file + '.\n' if verbose
