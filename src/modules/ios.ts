import * as fs from 'fs-extra'
import * as path from 'path'
import * as _ from 'lodash'
import gm from 'gm'

im = gm.subClass({
  imageMagick: true
});

import * as async from 'async'
import * as walk from 'walkdir'
import * as tmp from 'temporary'

import iOSXCAssets from './ios-xcassets'
import iOSConstants from './ios-constants'

import util from '../utilities'

var inputDirectory = ''
var outputDirectory = ''
var temporaryDirectory = ''

var options = {}

const defaults = {
  minimum: 1,
  maximum: 3,
  minimumPhone: 2,
  maximumPhone: 3,
  minimumPad: 1,
  maximumPad: 2,
  xcassets: false
};

type Device = {
  highestScale: number
}

type InfoDevices = {
  devices: Array<Device>
}

type Task = {
  info: InfoDevices
  scale: number
  device: string
}

 function processImage (task: Task, callback) {
  info = task.info
  const scaleKey = '' + task.scale
  const highestScale = info.devices[task.device].highestScale;
  const scaleSuffix = task.scale === 1 ? '' : "@" + task.scale + "x";
  const deviceSuffix = task.device === 'universal' ? '' : '~' + task.device;
  if (task.scale > highestScale) {
    if (info.id.indexOf('AppIcon') !== 0 && info.id.indexOf('Default') !== 0) {
      process.stdout.write("WARNING: Missing image " + (info.id + scaleSuffix + deviceSuffix + info.extension) + "\n");
    }
    return callback();
  }
  fs.ensureDirSync(temporaryDirectory + info.foldername);
  if (_.has(info.devices[task.device], scaleKey)) {
    image = im(info.devices[task.device][scaleKey]);
  } else {
    image = im(info.devices[task.device]['' + highestScale]).out('-define', 'png:exclude-chunk=tIME,tEXt,zTXt,date');
  }
  return image.size(function(err, size) {
    var appIconRoot, appIconRootSuffix, destinationPath, expectedHeight, expectedSize, expectedWidth, iPhoneOutputPath, launchImageInfo, outputPath, scaleRatio, unchangedOutputPath;
    if (err) {
      process.stdout.write(err + '\n');
    }
    outputPath = info.id + scaleSuffix + deviceSuffix + info.extension;
    if (info.id.indexOf('AppIcon') === 0) {
      unchangedOutputPath = outputPath;
      iPhoneOutputPath = info.id + scaleSuffix + '~iphone' + info.extension;
      if (_.contains(iOSConstants.appIconList, iOSConstants.bareFormat(outputPath, 'AppIcon')) || _.contains(iOSConstants.appIconList, iOSConstants.bareFormat(iPhoneOutputPath, 'AppIcon'))) {
        if (!_.contains(iOSConstants.appIconList, iOSConstants.bareFormat(outputPath, 'AppIcon')) && _.contains(iOSConstants.appIconList, iOSConstants.bareFormat(iPhoneOutputPath, 'AppIcon'))) {
          task.device = 'iphone';
          deviceSuffix = '~iphone';
          outputPath = iPhoneOutputPath;
        }
        expectedSize = iOSConstants.getAppIconInfo(outputPath).size;
        if (expectedSize !== size.width || expectedSize !== size.height) {
          process.stdout.write("WARNING: App Icon " + unchangedOutputPath + " should be " + expectedSize + "x" + expectedSize + ", but it is " + size.width + "x" + size.height + ".\n");
        }
      } else {
        process.stdout.write("WARNING: Unknown App Icon " + outputPath + "\n");
        return callback();
      }
    }
    if (info.id.indexOf('Default') === 0) {
      unchangedOutputPath = outputPath;
      iPhoneOutputPath = info.id + scaleSuffix + '~iphone' + info.extension;
      if (_.contains(iOSConstants.launchImageList, outputPath) || _.contains(iOSConstants.launchImageList, iPhoneOutputPath)) {
        if (!_.contains(iOSConstants.launchImageList, outputPath) && _.contains(iOSConstants.launchImageList, iPhoneOutputPath)) {
          task.device = 'iphone';
          deviceSuffix = '~iphone';
          outputPath = iPhoneOutputPath;
        }
        launchImageInfo = iOSConstants.getLaunchImageInfo(outputPath);
        expectedWidth = launchImageInfo.width;
        expectedHeight = launchImageInfo.height;
        if (expectedWidth !== size.width || expectedHeight !== size.height) {
          process.stdout.write("WARNING: Launch Image " + unchangedOutputPath + " should be " + expectedWidth + "x" + expectedHeight + ", but it is " + size.width + "x" + size.height + ".\n");
        }
      } else {
        process.stdout.write("WARNING: Unknown Launch Image " + outputPath + "\n");
        return callback();
      }
    }
    if (options.xcassets) {
      if (info.id.indexOf('AppIcon') === 0) {
        appIconRoot = info.id.split(/-|~|@/)[0];
        appIconRootSuffix = appIconRoot.substr(7);
        outputPath = ("AppIcon" + appIconRootSuffix + ".appiconset/") + info.id + scaleSuffix + deviceSuffix + info.extension;
        fs.ensureDirSync(path.resolve(temporaryDirectory, "AppIcon" + appIconRootSuffix + ".appiconset/"));
      } else if (info.id.indexOf('Default') === 0) {
        outputPath = 'LaunchImage.launchimage/' + info.id + scaleSuffix + deviceSuffix + info.extension;
        fs.ensureDirSync(path.resolve(temporaryDirectory, 'LaunchImage.launchimage/'));
      } else {
        outputPath = info.id + '.imageset/' + info.basename + scaleSuffix + deviceSuffix + info.extension;
        fs.ensureDirSync(path.resolve(temporaryDirectory, info.id + '.imageset/'));
      }
    }
    destinationPath = path.resolve(temporaryDirectory, outputPath);
    if (_.has(info.devices[task.device], scaleKey)) {
      if (info.id.indexOf('AppIcon') === 0) {
        return image.out('-background', 'white').out('-alpha', 'remove').out('-define', 'png:exclude-chunk=tIME,tEXt,zTXt,date').write(destinationPath, function(err) {
          if (err) {
            process.stdout.write(err + '\n');
          }
          if (options.verbose) {
            process.stdout.write("Copied prerendered App Icon " + (info.id + scaleSuffix + deviceSuffix + info.extension) + " and removed alpha channel.\n");
          }
          return callback();
        });
      } else {
        return fs.copy(info.devices[task.device][scaleKey], destinationPath, function() {
          if (options.verbose) {
            process.stdout.write("Copied prerendered image " + (info.id + scaleSuffix + deviceSuffix + info.extension) + "\n");
          }
          return callback();
        });
      }
    } else {
      scaleRatio = task.scale / highestScale;
      return image.filter(iOSConstants.resizeFilter).resize(Math.round(size.width * scaleRatio), Math.round(size.height * scaleRatio), '!').out('-define', 'png:exclude-chunk=tIME,tEXt,zTXt,date').write(destinationPath, function(err) {
        if (err) {
          process.stdout.write(err + '\n');
        }
        if (options.verbose) {
          process.stdout.write("Scaled image " + (info.id + scaleSuffix + deviceSuffix + info.extension) + "\n");
        }
        return callback();
      });
    }
  });
};

describeInputDirectory = function(inputDirectory) {
  var allowedExtensions, descriptor, device, deviceMatch, filepath, filtered, groupPaths, grouped, highestScale, i, identifier, imageDescriptors, len, paths, ref, scale, scaleMatch;
  paths = _.map(walk.sync(inputDirectory), function(filepath) {
    return filepath.replace(inputDirectory, '');
  });
  allowedExtensions = options.xcassets ? iOSConstants.xcassetsAllowedExtensions : iOSConstants.directoryAllowedExtensions;
  filtered = _.filter(paths, function(filepath) {
    var extension, i, len, pathSegments, segment;
    if (!fs.lstatSync(path.resolve(inputDirectory, filepath)).isFile()) {
      return false;
    }
    if (path.basename(filepath).slice(0, 1) === '.') {
      return false;
    }
    extension = path.extname(filepath);
    if (!_.contains(allowedExtensions, extension)) {
      process.stdout.write("File " + filepath + " in unsupported format for current output.\n");
      return false;
    }
    pathSegments = util.removeTrailingSlash(filepath).split('/');
    for (i = 0, len = pathSegments.length; i < len; i++) {
      segment = pathSegments[i];
      if (segment.slice(0, 1) === '_') {
        return false;
      }
    }
    return true;
  });
  grouped = _.groupBy(filtered, function(filepath) {
    return filepath.slice(0, path.extname(filepath).length * -1).replace(/@(\d+)x/, '').replace(/~([a-z]+)/, '');
  });
  imageDescriptors = [];
  for (identifier in grouped) {
    groupPaths = grouped[identifier];
    descriptor = {
      id: identifier,
      basename: path.basename(identifier),
      extension: path.extname(groupPaths[0]),
      devices: {}
    };
    descriptor.foldername = path.dirname(identifier);
    if (descriptor.foldername === '.') {
      descriptor.foldername = '';
    } else {
      descriptor.foldername += '/';
    }
    if (descriptor.extension === '.jpeg') {
      descriptor.extension = '.jpg';
    }
    for (i = 0, len = groupPaths.length; i < len; i++) {
      filepath = groupPaths[i];
      scaleMatch = filepath.match(/@(\d+)x/);
      scale = scaleMatch ? parseInt(scaleMatch[1]) : 1;
      deviceMatch = filepath.match(/~([a-z]+)/i);
      device = deviceMatch ? deviceMatch[1].toLowerCase() : 'universal';
      if (!_.has(descriptor.devices, device)) {
        descriptor.devices[device] = {};
      }
      descriptor.devices[device][scale] = path.resolve(inputDirectory, filepath);
    }
    ref = descriptor.devices;
    for (device in ref) {
      groupPaths = ref[device];
      highestScale = _.max(_.keys(groupPaths), function(key) {
        return parseInt(key);
      });
      descriptor.devices[device].highestScale = parseInt(highestScale);
    }
    if (options.xcassets && (_.has(descriptor.devices, 'iphone') || _.has(descriptor.devices, 'ipad')) && _.has(descriptor.devices, 'universal') && !(identifier.indexOf('AppIcon') === 0 || identifier.indexOf('Default') === 0)) {
      delete descriptor.devices.universal;
    }
    imageDescriptors.push(descriptor);
  }
  return imageDescriptors;
};

module.exports = function(passedInputDirectory, passedOutputDirectory, passedOptions, callback) {
  var absoluteMaxDensity, absoluteMinDensity, adjustedMaxDensity, adjustedMinDensity, adjustments, descriptor, device, i, imageDescriptors, len, maxDensity, minDensity, outputDirectoryBase, outputDirectoryName, queue, ref, ref1, results, scale, temporaryDirectoryObject;
  if (passedOutputDirectory == null) {
    passedOutputDirectory = false;
  }
  if (passedOptions == null) {
    passedOptions = {};
  }
  if (callback == null) {
    callback = false;
  }
  inputDirectory = util.addTrailingSlash(util.resolvePath(passedInputDirectory));
  outputDirectory = passedOutputDirectory;
  options = _.defaults(passedOptions, defaults);
  if (!callback) {
    callback = function() {};
  }
  options.minimum = parseInt(options.minimum);
  options.maximum = parseInt(options.maximum);
  options.minimumPhone = parseInt(options.minimumPhone);
  options.maximumPhone = parseInt(options.maximumPhone);
  options.minimumPad = parseInt(options.minimumPad);
  options.maximumPad = parseInt(options.maximumPad);
  outputDirectoryName = passedOutputDirectory ? util.removeTrailingSlash(passedOutputDirectory) : 'Images';
  if (options.xcassets && !_.endsWith(outputDirectoryName, '.xcassets')) {
    outputDirectoryName += '.xcassets';
  }
  outputDirectoryBase = util.resolvePath(inputDirectory, '..');
  outputDirectory = util.addTrailingSlash(util.resolvePath(outputDirectoryBase, outputDirectoryName));
  temporaryDirectoryObject = new tmp.Dir;
  temporaryDirectory = util.addTrailingSlash(temporaryDirectoryObject.path);
  queue = async.queue(processImage, 1);
  queue.drain = function() {
    util.move(temporaryDirectory, outputDirectory, options.clean);
    fs.removeSync(temporaryDirectory);
    if (options.xcassets) {
      return iOSXCAssets(outputDirectory, {
        verbose: options.verbose
      }, callback);
    } else {
      return callback();
    }
  };
  imageDescriptors = describeInputDirectory(inputDirectory);
  ref = iOSConstants.deviceTypes;
  results = [];
  for (i = 0, len = ref.length; i < len; i++) {
    device = ref[i];
    ref1 = iOSConstants.getDensityLimits(device, options), minDensity = ref1[0], maxDensity = ref1[1], absoluteMinDensity = ref1[2], absoluteMaxDensity = ref1[3];
    results.push((function() {
      var j, len1, results1;
      results1 = [];
      for (j = 0, len1 = imageDescriptors.length; j < len1; j++) {
        descriptor = imageDescriptors[j];
        if (_.has(descriptor.devices, device)) {
          adjustedMinDensity = minDensity;
          adjustedMaxDensity = maxDensity;
          if (_.has(iOSConstants.scalerExceptions, descriptor.id)) {
            adjustments = iOSConstants.scalerExceptions[descriptor.id];
            if (adjustments.minDensity) {
              adjustedMinDensity = adjustments.minDensity;
            }
            if (adjustments.maxDensity) {
              adjustedMaxDensity = adjustments.maxDensity;
            }
          }
          scale = adjustedMinDensity;
          while (scale <= adjustedMaxDensity) {
            queue.push({
              info: descriptor,
              device: device,
              scale: scale
            });
            scale++;
          }
          results1.push((function() {
            var results2;
            results2 = [];
            for (scale in descriptor.devices[device]) {
              if (scale === 'highestScale') {
                scale++;
                continue;
              }
              scale = parseInt(scale);
              if ((scale < adjustedMinDensity || scale > adjustedMaxDensity) && scale >= absoluteMinDensity && scale <= absoluteMaxDensity) {
                results2.push(queue.push({
                  info: descriptor,
                  device: device,
                  scale: scale
                }));
              } else {
                results2.push(void 0);
              }
            }
            return results2;
          })());
        } else {
          results1.push(void 0);
        }
      }
      return results1;
    })());
  }
  return results;
};
