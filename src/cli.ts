#!/usr/bin/env node
;
var argv, doc, info;

import * as fs from 'fs-extra'
import * as path from 'path'
import * as _ from 'lodash'
import * as colors from 'colors'

argv = require('minimist')(process.argv.slice(2), {
  boolean: ['i', 'a', 'c', 'v', 'x']
});

info = require('../package.json');

// (colors.bold('AssetPress ' + info.version)) +
doc = `
High quality asset resizer for iOS and Android and powerful workflow tool.
or more information see the README.

${ colors.bold('Usage and Common Options') }
Usage: assetpress [options] input
  -i, --ios         iOS mode. Default, flag is not necessary.
  -a, --android     Android mode.
      --input       Input directory. Flag not necessary,
                    any free argument is considered input.
  -o, --output      Output directory. Default depends on OS mode.
  -s, --screens     Screens directory
      --no-resize   Don't perform any image resizing.
                    Use when you only want split screens and images.
  -c, --clean       Clean output directory before outputting.
  -v, --verbose     Verbose output.
  -m, --git-message Workflow git commit message
      --git-no-push Don't push created git commit
      --workflow    Workflow JSON object instead of file

Input can be either a source directory or a .assetpress.json workflow file.
For more information about Workflows and configuration files see README.
Workflow accepts --clean and --verbose flags.

${ colors.bold('iOS Features and Options') }
- Resizing from higher resolutions to lower (@4x recommended)
- Xcassets folder generator, including AppIcon, LaunchImage and nested groups.

For detailed documentation about these features see the README.
  -x, --ios-xcassets  Generate .xcassets folder instead of a simple directory.
      --ios-min       Smallest generated size for universal assets. Default: 1x.
      --ios-max       Largest generated size for universal assets. Default: 3x.
      --ios-min-phone Smallest generated size for iPhone assets. Default: 2x.
      --ios-max-phone Largest generated size for iPhone assets. Default: 3x.
      --ios-min-pad   Smallest generated size for iPad assets. Default: 1x.
      --ios-max-pad   Largest generated size for iPad assets. Default: 2x.

${ colors.bold('Android Features and Options') }
- Resizing from higher resolutions to lower (xxxhdpi initial size required)
- 9-patches resizing with flexible initial patch thickness.
- NoDPI support.

AssetPress works either in iOS or Android mode, iOS being the default.
Activate Android mode with -a or --android.
Keep in mind that xxxhdpi (4x) initial resolution is required.
AssetPress will skip files that are not sized in multiples of 4.
For detailed documentation about these features see the README.
      --android-ldpi      Enable LDPI size generation.
      --android-xxxhdpi   Enable XXHDPI size generation.
                          Despite being the source of all other sizes, by
                          default XXXHDPI size is not generated.
`

if (argv.help || argv.h) {
  return process.stdout.write(doc);
}

if (argv.version) {
  return process.stdout.write("AssetPress version " + info.version + "\n");
}

require('./assetpress')({
  verbose: argv.verbose || argv.v,
  clean: argv.clean || argv.c,
  inputDirectory: _.isString(argv.input) ? argv.input : argv._.length ? argv._[0] : void 0,
  outputDirectory: _.isString(argv.output || argv.o) ? argv.output || argv.o : void 0,
  os: argv.ios || argv.i ? 'ios' : argv.android || argv.a ? 'android' : void 0,
  screensDirectory: _.isString(argv.screens || argv.s) ? argv.screens || argv.s : void 0,
  skipResize: argv['skip-resize'],
  iosMinimum: argv['ios-min'],
  iosMaximum: argv['ios-max'],
  iosMinimumPhone: argv['ios-min-phone'],
  iosMaximumPhone: argv['ios-max-phone'],
  iosMinimumPad: argv['ios-min-pad'],
  iosMaximumPad: argv['ios-max-pad'],
  iosXcassets: argv['ios-xcassets'] || argv.x,
  androidLdpi: argv['android-ldpi'],
  androidXxxhdpi: argv['android-xxxhdpi'],
  workflowObject: argv.workflow,
  gitMessage: argv['git-message'] || argv.m,
  gitRoot: argv['git-root'],
  gitBranch: argv['git-branch'],
  gitPrefix: argv['git-prefix'],
  gitRemote: argv['git-remote'],
  gitNoPush: argv['git-no-push']
});
