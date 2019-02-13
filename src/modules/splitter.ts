var _, defaults, fs, options, path, temporaryDirectory, tmp, util, walk;

fs = require('fs-extra');

path = require('path');

_ = require('lodash');

walk = require('walkdir');

tmp = require('temporary');

util = require('../utilities');

temporaryDirectory = '';

options = {};

defaults = {
  verbose: false,
  clean: false
};

module.exports = function(source, resourcesDestination, screensDestination, passedOptions, callback) {
  var filename, i, len, ref, resourcesDestinationDirectory, screensDestinationDirectory, sourceDirectory, temporaryDirectoryObject, tmpResourcesDirectory, tmpScreensDirectory;
  if (source == null) {
    source = process.cwd();
  }
  if (resourcesDestination == null) {
    resourcesDestination = './resources';
  }
  if (screensDestination == null) {
    screensDestination = './screens';
  }
  if (passedOptions == null) {
    passedOptions = {};
  }
  if (callback == null) {
    callback = false;
  }
  options = _.defaults(passedOptions, defaults);
  if (!callback) {
    callback = function() {};
  }
  sourceDirectory = util.resolvePath(source);
  resourcesDestinationDirectory = util.resolvePath(source, resourcesDestination);
  screensDestinationDirectory = util.resolvePath(source, screensDestination);
  temporaryDirectoryObject = new tmp.Dir;
  temporaryDirectory = temporaryDirectoryObject.path;
  temporaryDirectory = util.addTrailingSlash(temporaryDirectory);
  tmpResourcesDirectory = temporaryDirectory + 'resources';
  tmpScreensDirectory = temporaryDirectory + 'screens';
  fs.mkdirsSync(tmpResourcesDirectory);
  fs.mkdirsSync(tmpScreensDirectory);
  ref = fs.readdirSync(sourceDirectory);
  for (i = 0, len = ref.length; i < len; i++) {
    filename = ref[i];
    if (/^(\d+)\.(\d+)/.test(filename)) {
      fs.renameSync(path.resolve(sourceDirectory, filename), path.resolve(tmpScreensDirectory, filename));
      if (options.verbose) {
        process.stdout.write("Screen " + filename + " moved.\n");
      }
    } else {
      fs.renameSync(path.resolve(sourceDirectory, filename), path.resolve(tmpResourcesDirectory, filename));
      if (options.verbose) {
        process.stdout.write("Image " + filename + " moved.\n");
      }
    }
  }
  util.move(tmpResourcesDirectory, resourcesDestinationDirectory, options.clean);
  util.move(tmpScreensDirectory, screensDestinationDirectory, options.clean);
  fs.removeSync(temporaryDirectory);
  return callback();
};
