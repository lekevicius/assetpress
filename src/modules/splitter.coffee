fs = require 'fs-extra'
path = require 'path'

_ = require 'lodash'
walk = require 'walkdir'
tmp = require 'temporary'

util = require '../utilities'

temporaryDirectory = ''
options = {}

defaults =
  verbose: false
  clean: false

module.exports = (
  source = process.cwd(), 
  resourcesDestination = './resources', 
  screensDestination = './screens', 
  passedOptions = {}, 
  callback = false) ->

  options = _.defaults passedOptions, defaults
  unless callback then callback = -> # noop

  # Making all paths absolute
  sourceDirectory = util.resolvePath source
  resourcesDestinationDirectory = util.resolvePath source, resourcesDestination
  screensDestinationDirectory = util.resolvePath source, screensDestination

  temporaryDirectoryObject = new tmp.Dir
  temporaryDirectory = temporaryDirectoryObject.path
  temporaryDirectory = util.addTrailingSlash temporaryDirectory

  tmpResourcesDirectory = temporaryDirectory + 'resources'
  tmpScreensDirectory = temporaryDirectory + 'screens'
  
  fs.mkdirsSync tmpResourcesDirectory
  fs.mkdirsSync tmpScreensDirectory

  for filename in fs.readdirSync sourceDirectory
    # The magic of splitter: moves everything named starting with <NUMBER>.<NUMBER> to screens, anything else to resources
    if /^(\d+)\.(\d+)/.test(filename)
      fs.renameSync path.resolve(sourceDirectory, filename), path.resolve(tmpScreensDirectory, filename)
      process.stdout.write "Screen #{ filename } moved.\n" if options.verbose
    else
      fs.renameSync path.resolve(sourceDirectory, filename), path.resolve(tmpResourcesDirectory, filename)
      process.stdout.write "Image #{ filename } moved.\n" if options.verbose

  util.move tmpResourcesDirectory, resourcesDestinationDirectory, options.clean
  util.move tmpScreensDirectory, screensDestinationDirectory, options.clean

  fs.removeSync temporaryDirectory
  
  callback()
