var AUTHOR, _, completeContentsJSONForImage, completedModifierAction, contentsJSONForAppIcon, contentsJSONForImage, contentsJSONForLaunchImage, defaults, fs, getResizingObject, hasAnyModifier, iOSConstants, im, options, outputDirectory, path, pngparse, readPixelRow, remove9Patches, removeModifier, run9PatchModifier, runModifierActions, runTemplateModifier, stringRemoveModifier, stringWithoutModifiers, supportedModifiers, util, walk;

fs = require('fs-extra');

path = require('path');

_ = require('lodash');

walk = require('walkdir');

pngparse = require('pngparse');

im = require('gm').subClass({
  imageMagick: true
});

iOSConstants = require('./ios-constants');

util = require('../utilities');

AUTHOR = "assetpress";

outputDirectory = '';

options = {};

defaults = {
  verbose: false
};

supportedModifiers = ['template', '9'];

hasAnyModifier = function(basename) {
  var i, len, modifier;
  for (i = 0, len = supportedModifiers.length; i < len; i++) {
    modifier = supportedModifiers[i];
    if (_.endsWith(basename, "." + modifier)) {
      return modifier;
    }
  }
  return false;
};

stringRemoveModifier = function(string, modifier) {
  return string.replace("." + modifier, '');
};

stringWithoutModifiers = function(string) {
  var i, len, modifier;
  for (i = 0, len = supportedModifiers.length; i < len; i++) {
    modifier = supportedModifiers[i];
    string = string.replace("." + modifier, '');
  }
  return string;
};

removeModifier = function(modifier, filenames, directory, contents, basename) {
  var directoryPath, file, i, len, ref;
  directoryPath = path.resolve(outputDirectory, directory);
  ref = fs.readdirSync(directoryPath);
  for (i = 0, len = ref.length; i < len; i++) {
    file = ref[i];
    if (!(file.indexOf("." + modifier) > 0)) {
      continue;
    }
    fs.renameSync(path.resolve(directoryPath, file), path.resolve(directoryPath, stringRemoveModifier(file, modifier)));
  }
  fs.renameSync(directoryPath, stringRemoveModifier(directoryPath, modifier));
  filenames = _.map(filenames, function(filename) {
    return stringRemoveModifier(filename, modifier);
  });
  directory = stringRemoveModifier(directory, modifier);
  basename = stringRemoveModifier(basename, modifier);
  return [filenames, directory, contents, basename];
};

runTemplateModifier = function(filenames, directory, contents, basename, callback) {
  contents.info['template-rendering-intent'] = 'template';
  return completedModifierAction('template', filenames, directory, contents, basename, callback);
};

remove9Patches = function(filesToCrop, filenames, directory, contents, basename, callback) {
  var cropImage, fileToCrop, imagePath, imageScale, scaledPatchInfo;
  if (filesToCrop.length) {
    fileToCrop = filesToCrop.pop();
    scaledPatchInfo = fileToCrop.match(/@(\d+)x/i);
    imageScale = scaledPatchInfo ? parseInt(scaledPatchInfo[1]) : 1;
    imagePath = path.resolve(outputDirectory, directory, fileToCrop);
    cropImage = im(imagePath);
    return cropImage.size(function(err, size) {
      return cropImage.crop(size.width - 2 * imageScale, size.height - 2 * imageScale, imageScale, imageScale).out('-define', 'png:exclude-chunk=tIME,tEXt,zTXt,date').write(imagePath, function(err) {
        if (err) {
          process.stdout.write(err + '\n');
        }
        if (options.verbose) {
          process.stdout.write("Cropped 9-patch image " + imagePath + "\n");
        }
        return remove9Patches(filesToCrop, filenames, directory, contents, basename, callback);
      });
    });
  } else {
    return completedModifierAction('9', filenames, directory, contents, basename, callback);
  }
};

readPixelRow = function(data, row, scale) {
  var alpha, alphas, currentGroup, groups, i, j, k, len, offset, ref, ref1, ref2, ref3, ref4, ref5, result, x, y;
  alphas = [];
  switch (row) {
    case 'top':
      y = 0;
      for (x = i = ref = scale, ref1 = data.width - 1 - scale, ref2 = scale; ref2 > 0 ? i <= ref1 : i >= ref1; x = i += ref2) {
        offset = (y * data.width + x) * 4;
        alphas.push(data.data[offset + 3]);
      }
      break;
    case 'left':
      x = 0;
      for (y = j = ref3 = scale, ref4 = data.height - 1 - scale, ref5 = scale; ref5 > 0 ? j <= ref4 : j >= ref4; y = j += ref5) {
        offset = (y * data.width + x) * 4;
        alphas.push(data.data[offset + 3]);
      }
  }
  groups = [];
  currentGroup = [0, alphas[0] > 128];
  for (k = 0, len = alphas.length; k < len; k++) {
    alpha = alphas[k];
    if ((alpha > 128) !== currentGroup[1]) {
      groups.push(_.clone(currentGroup));
      currentGroup = [0, alpha > 128];
    }
    currentGroup[0] += 1;
  }
  groups.push(_.clone(currentGroup));
  result = {
    startInset: 0,
    center: 0,
    endInset: 0
  };
  if (groups.length === 3 && groups[0][1] === false && groups[1][1] === true && groups[2][1] === false) {
    result.startInset = groups[0][0];
    result.center = groups[1][0];
    result.endInset = groups[2][0];
  } else if (groups.length === 2) {
    if (groups[0][1] === false && groups[1][1] === true) {
      result.startInset = groups[0][0];
      result.center = groups[1][0];
    } else if (groups[0][1] === true && groups[1][1] === false) {
      result.center = groups[0][0];
      result.endInset = groups[1][0];
    } else {
      return false;
    }
  } else if (groups.length === 1 && groups[0][1] === true) {
    result.center = groups[0][0];
  } else {
    return false;
  }
  return result;
};

getResizingObject = function(data, scale) {
  var leftRowInfo, resizing, topRowInfo;
  topRowInfo = readPixelRow(data, 'top', scale);
  leftRowInfo = readPixelRow(data, 'left', scale);
  if (topRowInfo || leftRowInfo) {
    resizing = {
      mode: '',
      center: {
        mode: 'fill'
      },
      capInsets: {}
    };
    if (topRowInfo && leftRowInfo) {
      resizing.mode = '9-part';
    } else if (topRowInfo) {
      resizing.mode = '3-part-horizontal';
    } else {
      resizing.mode = '3-part-vertical';
    }
    if (topRowInfo) {
      resizing.center.width = topRowInfo.center;
      resizing.capInsets.left = topRowInfo.startInset;
      resizing.capInsets.right = topRowInfo.endInset;
    }
    if (leftRowInfo) {
      resizing.center.height = leftRowInfo.center;
      resizing.capInsets.top = leftRowInfo.startInset;
      resizing.capInsets.bottom = leftRowInfo.endInset;
    }
    return resizing;
  } else {
    return false;
  }
};

run9PatchModifier = function(filenames, directory, contents, basename, callback) {
  var imagePath, imageScale, scaledPatchInfo;
  scaledPatchInfo = filenames[0].match(/@(\d+)x/i);
  imageScale = scaledPatchInfo ? parseInt(scaledPatchInfo[1]) : 1;
  imagePath = path.resolve(outputDirectory, directory, filenames[0]);
  return pngparse.parseFile(imagePath, function(err, data) {
    var filename, filesToCrop, i, len, resizingObject, scaledResizingObject;
    if (err) {
      process.stdout.write(err);
    }
    resizingObject = getResizingObject(data, imageScale);
    contents['__additions'] = {};
    for (i = 0, len = filenames.length; i < len; i++) {
      filename = filenames[i];
      filename = stringWithoutModifiers(filename);
      scaledPatchInfo = filename.match(/@(\d+)x/i);
      imageScale = scaledPatchInfo ? parseInt(scaledPatchInfo[1]) : 1;
      scaledResizingObject = _.cloneDeep(resizingObject);
      if (scaledResizingObject.center.width) {
        scaledResizingObject.center.width *= imageScale;
      }
      if (scaledResizingObject.center.height) {
        scaledResizingObject.center.height *= imageScale;
      }
      if (scaledResizingObject.capInsets.top) {
        scaledResizingObject.capInsets.top *= imageScale;
      }
      if (scaledResizingObject.capInsets.right) {
        scaledResizingObject.capInsets.right *= imageScale;
      }
      if (scaledResizingObject.capInsets.bottom) {
        scaledResizingObject.capInsets.bottom *= imageScale;
      }
      if (scaledResizingObject.capInsets.left) {
        scaledResizingObject.capInsets.left *= imageScale;
      }
      contents['__additions'][filename] = {
        resizing: scaledResizingObject
      };
    }
    filesToCrop = _.clone(filenames);
    return remove9Patches(filesToCrop, filenames, directory, contents, basename, callback);
  });
};

completedModifierAction = function(modifier, filenames, directory, contents, basename, callback) {
  var ref;
  ref = removeModifier(modifier, filenames, directory, contents, basename), filenames = ref[0], directory = ref[1], contents = ref[2], basename = ref[3];
  if (hasAnyModifier(basename)) {
    return runModifierActions(filenames, directory, contents, basename, callback);
  } else {
    return completeContentsJSONForImage(filenames, directory, contents, basename, callback);
  }
};

runModifierActions = function(filenames, directory, contents, basename, callback) {
  var modifier;
  modifier = hasAnyModifier(basename);
  if (modifier === 'template') {
    runTemplateModifier(filenames, directory, contents, basename, callback);
  }
  if (modifier === '9') {
    return run9PatchModifier(filenames, directory, contents, basename, callback);
  }
};

contentsJSONForImage = function(filenames, directory, callback) {
  var basename, contents, directoryName;
  contents = {
    images: [],
    info: {
      version: 1,
      author: AUTHOR
    }
  };
  directoryName = directory.split('/').pop();
  basename = directoryName.slice(0, path.extname(directoryName).length * -1);
  if (hasAnyModifier(basename)) {
    return runModifierActions(filenames, directory, contents, basename, callback);
  } else {
    return completeContentsJSONForImage(filenames, directory, contents, basename, callback);
  }
};

completeContentsJSONForImage = function(filenames, directory, contents, basename, callback) {
  var extension, firstFilename, i, idiom, imageInfo, isDeviceSpecific, len, possibleName, possibleNames, scale, scaleSuffix;
  firstFilename = filenames[0];
  isDeviceSpecific = !!firstFilename.match(/~([a-z]+)/);
  extension = path.extname(firstFilename);
  if (extension === '.jpg') {
    contents.info['template-rendering-intent'] = 'original';
  }
  possibleNames = [];
  if (isDeviceSpecific) {
    scale = 1;
    while (scale <= 3) {
      scaleSuffix = scale === 1 ? '' : "@" + scale + "x";
      possibleNames.push(basename + scaleSuffix + '~iphone' + extension);
      scale++;
    }
    scale = 1;
    while (scale <= 2) {
      scaleSuffix = scale === 1 ? '' : "@" + scale + "x";
      possibleNames.push(basename + scaleSuffix + '~ipad' + extension);
      scale++;
    }
  } else {
    scale = 1;
    while (scale <= 3) {
      scaleSuffix = scale === 1 ? '' : "@" + scale + "x";
      possibleNames.push(basename + scaleSuffix + extension);
      scale++;
    }
  }
  for (i = 0, len = possibleNames.length; i < len; i++) {
    possibleName = possibleNames[i];
    idiom = possibleName.match(/~([a-z]+)/);
    idiom = idiom ? idiom[1] : 'universal';
    scale = possibleName.match(/@(\d+)x/);
    scale = scale ? scale[1] + 'x' : '1x';
    imageInfo = {
      idiom: idiom,
      scale: scale
    };
    if (_.contains(filenames, possibleName)) {
      imageInfo.filename = possibleName;
    }
    if (_.has(contents['__additions'], possibleName)) {
      imageInfo = _.assign(imageInfo, contents['__additions'][possibleName]);
    }
    contents.images.push(imageInfo);
  }
  delete contents['__additions'];
  return callback(null, contents, directory);
};

contentsJSONForAppIcon = function(filenames, directory) {
  var appIconConflict, appIconInfo, appIconName, conflictSkipList, contents, filteredAppIconList, i, idiom, imageInfo, j, k, len, len1, len2, merged, ref, scale, scaledSize, size, subtype;
  contents = {
    images: [],
    info: {
      version: 1,
      author: AUTHOR
    },
    properties: {
      'pre-rendered': true
    }
  };
  filteredAppIconList = iOSConstants.resourceListWithRequiredGroups(filenames, iOSConstants.appIconGroups, 'AppIcon');
  conflictSkipList = [];
  for (i = 0, len = filteredAppIconList.length; i < len; i++) {
    appIconName = filteredAppIconList[i];
    appIconInfo = iOSConstants.getAppIconInfo(appIconName);
    if (appIconInfo && appIconInfo.conflicts) {
      merged = _.union([appIconName], appIconInfo.conflicts);
      if (_.intersection(filenames, merged).length > 1) {
        filenames = _.difference(filenames, appIconInfo.conflicts);
        ref = appIconInfo.conflicts;
        for (j = 0, len1 = ref.length; j < len1; j++) {
          appIconConflict = ref[j];
          conflictSkipList.push(appIconConflict);
          fs.unlinkSync(outputDirectory + directory + '/' + appIconConflict);
        }
      }
    }
  }
  for (k = 0, len2 = filteredAppIconList.length; k < len2; k++) {
    appIconName = filteredAppIconList[k];
    if (conflictSkipList.indexOf(appIconName) > -1) {
      continue;
    }
    appIconInfo = iOSConstants.getAppIconInfo(appIconName);
    idiom = appIconName.match(/~([a-z]+)/);
    idiom = idiom ? idiom[1] : 'universal';
    scale = appIconName.match(/@(\d+)x/);
    scale = scale ? scale[1] : 1;
    if (appIconInfo && appIconInfo.settingSize) {
      size = appIconInfo.settingSize + 'x' + appIconInfo.settingSize;
    } else {
      scaledSize = Math.round(appIconInfo.size / scale);
      size = scaledSize + 'x' + scaledSize;
    }
    imageInfo = {
      size: size,
      idiom: idiom,
      scale: scale + 'x'
    };
    if (appIconInfo && appIconInfo.role) {
      imageInfo.role = appIconInfo.role;
    }
    subtype = iOSConstants.getImageSubtype(appIconName);
    if (subtype) {
      imageInfo.subtype = subtype;
    }
    if (_.contains(filenames, appIconName)) {
      imageInfo.filename = appIconName;
    }
    contents.images.push(imageInfo);
  }
  return contents;
};

contentsJSONForLaunchImage = function(filenames, directory) {
  var contents, filteredLaunchImageList, i, idiom, imageInfo, launchImageInfo, launchImageName, len, orientation, scale, subtype;
  contents = {
    images: [],
    info: {
      version: 1,
      author: AUTHOR
    }
  };
  filteredLaunchImageList = iOSConstants.resourceListWithRequiredGroups(filenames, iOSConstants.launchImageGroups, 'Default');
  for (i = 0, len = filteredLaunchImageList.length; i < len; i++) {
    launchImageName = filteredLaunchImageList[i];
    idiom = launchImageName.match(/~([a-z]+)/);
    idiom = idiom ? idiom[1] : 'universal';
    scale = launchImageName.match(/@(\d+)x/);
    scale = scale ? scale[1] + 'x' : '1x';
    orientation = /landscape/i.test(launchImageName) ? 'landscape' : 'portrait';
    imageInfo = {
      extent: 'full-screen',
      idiom: idiom,
      orientation: orientation,
      scale: scale
    };
    launchImageInfo = iOSConstants.getLaunchImageInfo(launchImageName);
    if (launchImageInfo && launchImageInfo.minimumSystemVersion) {
      imageInfo['minimum-system-version'] = launchImageInfo.minimumSystemVersion;
    }
    subtype = iOSConstants.getImageSubtype(launchImageName);
    if (subtype) {
      imageInfo.subtype = subtype;
    }
    if (_.contains(filenames, launchImageName)) {
      imageInfo.filename = launchImageName;
    }
    contents.images.push(imageInfo);
  }
  return contents;
};

export default function(passedOutputDirectory, passedOptions, callback) {
  var assetDirectories, contents, directory, directoryContents, extension, i, len, paths;
  outputDirectory = util.addTrailingSlash(util.resolvePath(passedOutputDirectory));
  options = _.defaults(passedOptions, defaults);
  paths = _.map(walk.sync(outputDirectory), function(filepath) {
    return filepath.replace(outputDirectory, '');
  });
  assetDirectories = _.filter(paths, function(filepath) {
    return /\.appiconset$/.test(filepath) || /\.launchimage$/.test(filepath) || /\.imageset$/.test(filepath);
  });
  for (i = 0, len = assetDirectories.length; i < len; i++) {
    directory = assetDirectories[i];
    extension = path.extname(directory);
    directoryContents = _(paths).filter(function(filepath) {
      return filepath.indexOf(directory + '/') === 0;
    }).map(function(filepath) {
      return filepath.replace(directory + '/', '');
    }).filter(function(filename) {
      return filename.slice(0, 1) !== '.' && filename !== 'Contents.json';
    }).value();
    contents = '{}';
    if (extension === '.appiconset') {
      contents = contentsJSONForAppIcon(directoryContents, directory);
    }
    if (extension === '.launchimage') {
      contents = contentsJSONForLaunchImage(directoryContents, directory);
    }
    if (extension === '.appiconset' || extension === '.launchimage') {
      fs.writeFileSync(path.join(outputDirectory, directory, 'Contents.json'), JSON.stringify(contents));
      if (options.verbose) {
        process.stdout.write("Created Contents.json for " + directory + "\n");
      }
    }
    if (extension === '.imageset') {
      contentsJSONForImage(directoryContents, directory, function(err, resultingContents, resultingDirectory) {
        if (err) {
          process.stdout.write("Error!\n");
        }
        fs.writeFileSync(path.join(outputDirectory, resultingDirectory, 'Contents.json'), JSON.stringify(resultingContents));
        if (options.verbose) {
          return process.stdout.write("Created Contents.json for " + resultingDirectory + "\n");
        }
      });
    }
  }
  return callback();
};
