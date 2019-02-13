_ = require('lodash');

export const resizeFilter = 'Box';

export const scalerExceptions = {
  'Default-Landscape736h': {
    minDensity: 3
  },
  'Default-Portrait736h': {
    minDensity: 3
  }
};

export const deviceTypes = ['universal', 'iphone', 'ipad', 'car', 'watch'];

export const directoryAllowedExtensions = ['.png', '.jpg', '.jpeg', '.gif'];

export const xcassetsAllowedExtensions = ['.png', '.jpg', '.jpeg'];

export const appIconGroups = {
  iOS8: {
    'AppIcon-Settings@3x~iphone.png': {
      size: 87
    },
    'AppIcon-Spotlight@3x~iphone.png': {
      size: 120
    },
    'AppIcon@3x~iphone.png': {
      size: 180
    }
  },
  iPhone: {
    'AppIcon-Settings@2x~iphone.png': {
      size: 58,
      conflicts: ['AppIcon-Legacy-Small@2x~iphone.png']
    },
    'AppIcon-Spotlight@2x~iphone.png': {
      size: 80
    },
    'AppIcon@2x~iphone.png': {
      size: 120
    }
  },
  iPad: {
    'AppIcon-Settings~ipad.png': {
      size: 29,
      conflicts: ['AppIcon-Legacy-Settings~ipad.png']
    },
    'AppIcon-Settings@2x~ipad.png': {
      size: 58,
      conflicts: ['AppIcon-Legacy-Settings@2x~ipad.png']
    },
    'AppIcon-Spotlight~ipad.png': {
      size: 40
    },
    'AppIcon-Spotlight@2x~ipad.png': {
      size: 80
    },
    'AppIcon~ipad.png': {
      size: 76
    },
    'AppIcon@2x~ipad.png': {
      size: 152
    }
  },
  car: {
    'AppIcon~car.png': {
      size: 120
    }
  },
  watch: {
    'AppIcon-NotificationCenter-38mm@2x~watch.png': {
      size: 48,
      role: 'notificationCenter'
    },
    'AppIcon-NotificationCenter-42mm@2x~watch.png': {
      size: 55,
      settingSize: '27.5',
      role: 'notificationCenter'
    },
    'AppIcon@2x~watch.png': {
      size: 80,
      role: 'appLauncher',
      settingSubtype: '38mm'
    },
    'AppIcon-LongLook-42mm@2x~watch.png': {
      size: 88,
      role: 'longLook'
    },
    'AppIcon-ShortLook-38mm@2x~watch.png': {
      size: 172,
      role: 'quickLook'
    },
    'AppIcon-ShortLook-42mm@2x~watch.png': {
      size: 196,
      role: 'quickLook'
    },
    'AppIcon-CompanionSettings@2x~watch.png': {
      size: 58,
      role: 'companionSettings'
    },
    'AppIcon-CompanionSettings@3x~watch.png': {
      size: 87,
      role: 'companionSettings'
    }
  },
  iPhoneLegacy: {
    'AppIcon-Legacy-Small~iphone.png': {
      size: 29
    },
    'AppIcon-Legacy-Small@2x~iphone.png': {
      size: 58
    },
    'AppIcon-Legacy~iphone.png': {
      size: 57
    },
    'AppIcon-Legacy@2x~iphone.png': {
      size: 114
    }
  },
  iPadLegacy: {
    'AppIcon-Legacy-Settings~ipad.png': {
      size: 29
    },
    'AppIcon-Legacy-Settings@2x~ipad.png': {
      size: 58
    },
    'AppIcon-Legacy-Spotlight~ipad.png': {
      size: 50
    },
    'AppIcon-Legacy-Spotlight@2x~ipad.png': {
      size: 100
    },
    'AppIcon-Legacy~ipad.png': {
      size: 72
    },
    'AppIcon-Legacy@2x~ipad.png': {
      size: 144
    }
  }
};

appIconList = [];

for (groupName in appIconGroups) {
  groupContents = appIconGroups[groupName];
  for (iconName in groupContents) {
    appIconList.push(iconName);
  }
}

module.exports.appIconGroups = appIconGroups;

module.exports.appIconList = appIconList;

launchImageGroups = {
  iOS8Portrait: {
    'Default-667h@2x~iphone.png': {
      minimumSystemVersion: '8.0',
      width: 750,
      height: 1334
    },
    'Default-Portrait736h@3x~iphone.png': {
      minimumSystemVersion: '8.0',
      width: 1242,
      height: 2208
    }
  },
  iOS8Landscape: {
    'Default-Landscape736h@3x~iphone.png': {
      minimumSystemVersion: '8.0',
      width: 2208,
      height: 1242
    }
  },
  iPhonePortrait: {
    'Default@2x~iphone.png': {
      minimumSystemVersion: '7.0',
      width: 640,
      height: 960
    },
    'Default-568h@2x~iphone.png': {
      minimumSystemVersion: '7.0',
      width: 640,
      height: 1136
    }
  },
  iPadPortrait: {
    'Default-Portrait~ipad.png': {
      minimumSystemVersion: '7.0',
      width: 768,
      height: 1024
    },
    'Default-Portrait@2x~ipad.png': {
      minimumSystemVersion: '7.0',
      width: 1536,
      height: 2048
    }
  },
  iPadLandscape: {
    'Default-Landscape~ipad.png': {
      minimumSystemVersion: '7.0',
      width: 1024,
      height: 768
    },
    'Default-Landscape@2x~ipad.png': {
      minimumSystemVersion: '7.0',
      width: 2048,
      height: 1536
    }
  },
  watch: {
    'Default-38mm@2x~watch.png': {
      minimumSystemVersion: '8.0',
      width: 272,
      height: 340
    },
    'Default-42mm@2x~watch.png': {
      minimumSystemVersion: '8.0',
      width: 312,
      height: 390
    }
  },
  iPhoneLegacyPortrait: {
    'Default-Legacy~iphone.png': {
      width: 320,
      height: 480
    },
    'Default-Legacy@2x~iphone.png': {
      width: 640,
      height: 960
    },
    'Default-Legacy-568h@2x~iphone.png': {
      width: 640,
      height: 1136
    }
  },
  iPadLegacyPortrait: {
    'Default-Legacy-Portrait~ipad.png': {
      width: 768,
      height: 1024
    },
    'Default-Legacy-Portrait@2x~ipad.png': {
      width: 1536,
      height: 2048
    }
  },
  iPadLegacyLandscape: {
    'Default-Legacy-Landscape~ipad.png': {
      width: 1024,
      height: 768
    },
    'Default-Legacy-Landscape@2x~ipad.png': {
      width: 2048,
      height: 1536
    }
  }
};

launchImageList = [];

for (groupName in launchImageGroups) {
  groupContents = launchImageGroups[groupName];
  for (launchImageName in groupContents) {
    launchImageList.push(launchImageName);
  }
}

module.exports.launchImageGroups = launchImageGroups;

module.exports.launchImageList = launchImageList;

module.exports.getDensityLimits = function(device, options) {
  var absoluteMaxDensity, absoluteMinDensity, maxDensity, minDensity;
  switch (device) {
    case 'iphone':
      minDensity = options.minimumPhone;
      maxDensity = options.maximumPhone;
      absoluteMinDensity = 1;
      absoluteMaxDensity = 3;
      break;
    case 'ipad':
      minDensity = options.minimumPad;
      maxDensity = options.maximumPad;
      absoluteMinDensity = 1;
      absoluteMaxDensity = 2;
      break;
    case 'car':
      minDensity = 1;
      maxDensity = 1;
      absoluteMinDensity = 1;
      absoluteMaxDensity = 1;
      break;
    case 'watch':
      minDensity = 2;
      maxDensity = 2;
      absoluteMinDensity = 2;
      absoluteMaxDensity = 3;
      break;
    case 'universal':
      minDensity = options.minimum;
      maxDensity = options.maximum;
      absoluteMinDensity = 1;
      absoluteMaxDensity = 3;
  }
  return [minDensity, maxDensity, absoluteMinDensity, absoluteMaxDensity];
};

module.exports.bareFormat = function(name, startingWith) {
  var barename, nameRoot, nameRootSuffix, specifier;
  nameRoot = name.split(/-|~|@/)[0];
  nameRootSuffix = nameRoot.substr(startingWith.length);
  specifier = name.substr(startingWith.length + nameRootSuffix.length);
  barename = startingWith + specifier;
  return barename;
};

module.exports.getAppIconInfo = function(needle) {
  var bareNeedle, filenames;
  bareNeedle = module.exports.bareFormat(needle, 'AppIcon');
  for (groupName in appIconGroups) {
    filenames = _.keys(appIconGroups[groupName]);
    if (_.contains(filenames, bareNeedle)) {
      return appIconGroups[groupName][bareNeedle];
    }
  }
  return false;
};

module.exports.getLaunchImageInfo = function(needle) {
  var filenames;
  for (groupName in launchImageGroups) {
    filenames = _.keys(launchImageGroups[groupName]);
    if (_.contains(filenames, needle)) {
      return launchImageGroups[groupName][needle];
    }
  }
  return false;
};

module.exports.getImageSubtype = function(filename) {
  var heightSubtype, iconInfo, number, watchSubtype;
  iconInfo = module.exports.getAppIconInfo(filename);
  if (iconInfo && iconInfo.settingSubtype) {
    return iconInfo.settingSubtype;
  }
  heightSubtype = filename.match(/(\d+)h/);
  if (heightSubtype) {
    number = parseInt(heightSubtype[1]);
    if (number === 568) {
      return 'retina4';
    }
    return number + 'h';
  }
  watchSubtype = filename.match(/(\d+)mm/);
  if (watchSubtype) {
    number = parseInt(watchSubtype[1]);
    return number + 'mm';
  }
  return false;
};

module.exports.resourceListWithRequiredGroups = function(filenames, groupedList, startingWith) {
  var bareFilenames, filteredGroups, firstFilename, key, keyWithReattachedSuffix, nameRoot, nameRootSuffix, requiredGroups, result, specifier, value;
  firstFilename = filenames[0];
  nameRoot = firstFilename.split(/-|~|@/)[0];
  nameRootSuffix = nameRoot.substr(startingWith.length);
  bareFilenames = _.map(filenames, function(name) {
    return module.exports.bareFormat(name, startingWith);
  });
  requiredGroups = (function() {
    var results;
    results = [];
    for (groupName in groupedList) {
      if (_.intersection(bareFilenames, _.keys(groupedList[groupName])).length) {
        results.push(groupName);
      }
    }
    return results;
  })();
  filteredGroups = _.pick(groupedList, requiredGroups);
  result = [];
  for (groupName in filteredGroups) {
    groupContents = filteredGroups[groupName];
    for (key in groupContents) {
      value = groupContents[key];
      specifier = key.substr(startingWith.length);
      keyWithReattachedSuffix = startingWith + nameRootSuffix + specifier;
      result.push(keyWithReattachedSuffix);
    }
  }
  return result;
};
