fs = require 'fs-extra'
path = require 'path'
_ = require 'lodash'
walk = require 'walkdir'
tmp = require 'temporary'
rimraf = require('rimraf').sync
util = require './utilities'

# Delete tmp directory

module.exports = (options) ->

  defaults =
    source: process.cwd()
    resourcesDestination: './resources'
    screensDestination: './screens'
    verbose: false
  options = _.defaults options, defaults

  sourceDirectory = util.resolvePath options.source
  resourcesDestinationDirectory = util.resolvePath options.resourcesDestination, options.source
  screensDestinationDirectory = util.resolvePath options.screensDestination, options.source

  temporaryDirectoryObject = new tmp.Dir
  temporaryDirectory = temporaryDirectoryObject.path
  temporaryDirectory += '/' if temporaryDirectory.slice(-1) isnt '/'

  tmpResourcesDirectory = temporaryDirectory + 'resources'
  fs.mkdirsSync tmpResourcesDirectory
  tmpScreensDirectory = temporaryDirectory + 'screens'
  fs.mkdirsSync tmpScreensDirectory

  files = fs.readdirSync sourceDirectory
  for filename in files
    if /^(\d+)\.(\d+)/.test(filename)
      fs.renameSync path.resolve(sourceDirectory, filename), path.resolve(tmpScreensDirectory, filename)
      process.stdout.write "Screen " + filename + " moved.\n" if options.verbose
    else
      fs.renameSync path.resolve(sourceDirectory, filename), path.resolve(tmpResourcesDirectory, filename)
      process.stdout.write "Image " + filename + " moved.\n" if options.verbose

  fs.removeSync sourceDirectory
  fs.removeSync resourcesDestinationDirectory
  fs.removeSync screensDestinationDirectory

  fs.mkdirpSync path.resolve(resourcesDestinationDirectory, '..')
  fs.renameSync tmpResourcesDirectory, resourcesDestinationDirectory
  fs.mkdirpSync path.resolve(screensDestinationDirectory, '..')
  fs.renameSync tmpScreensDirectory, screensDestinationDirectory

  fs.removeSync temporaryDirectory
