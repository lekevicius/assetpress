#!/usr/bin/env node
;

var argv, colors, doc, fs, info, path, _;

fs = require("fs-extra");
path = require("path");

_ = require("lodash");
colors = require("colors");
argv = require("minimist")(process.argv.slice(2), {
    boolean: ["i", "a", "c", "v", "x"]
});

// Package info is used by version reporter.
info = require("../package.json");

// Docstring
doc = "###fakeblock\n" + (colors.bold("AssetPress " + info.version)) + "\n###\nHigh quality asset resizer for iOS and Android and powerful workflow tool.\nFor more information see the README.\n\n###fakeblock\n" + (colors.bold("Usage and Common Options")) + "\n###\nUsage: assetpress [options] input\n  -i, --ios         iOS mode. Default, flag is not necessary.\n  -a, --android     Android mode.\n      --input       Input directory. Flag not necessary, \n                    any free argument is considered input.\n  -o, --output      Output directory. Default depends on OS mode.\n  -s, --screens     Screens directory\n      --no-resize   Don't perform any image resizing. \n                    Use when you only want split screens and images.\n  -c, --clean       Clean output directory before outputting.\n  -v, --verbose     Verbose output.\n  -m, --git-message Workflow git commit message\n      --git-no-push Don't push created git commit\n      --workflow    Workflow JSON object instead of file\nInput can be either a source directory or a .assetpress.json workflow file.\nFor more information about Workflows and configuration files see README.\nWorkflow accepts --clean and --verbose flags.\n\n###fakeblock\n" + (colors.bold("iOS Features and Options")) + "\n###\n- Resizing from higher resolutions to lower (@4x recommended)\n- Xcassets folder generator, including AppIcon, LaunchImage and nested groups.\nFor detailed documentation about these features see the README.\n  -x, --ios-xcassets  Generate .xcassets folder instead of a simple directory.\n      --ios-min       Smallest generated size for universal assets. Default: 1x.\n      --ios-max       Largest generated size for universal assets. Default: 3x.\n      --ios-min-phone Smallest generated size for iPhone assets. Default: 2x.\n      --ios-max-phone Largest generated size for iPhone assets. Default: 3x.\n      --ios-min-pad   Smallest generated size for iPad assets. Default: 1x.\n      --ios-max-pad   Largest generated size for iPad assets. Default: 2x.\n\n###fakeblock\n" + (colors.bold("Android Features and Options")) + "\n###\n- Resizing from higher resolutions to lower (xxxhdpi initial size required)\n- 9-patches resizing with flexible initial patch thickness.\n- NoDPI support.\n\nAssetPress works either in iOS or Android mode, iOS being the default.\nActivate Android mode with -a or --android.\nKeep in mind that xxxhdpi (4x) initial resolution is required.\nAssetPress will skip files that are not sized in multiples of 4.\nFor detailed documentation about these features see the README.\n      --android-ldpi      Enable LDPI size generation.\n      --android-xxxhdpi   Enable XXHDPI size generation. \n                          Despite being the source of all other sizes, by \n                          default XXXHDPI size is not generated.\n";
if (argv.help || argv.h) {
    return process.stdout.write(doc);
}

if (argv.version) {
    return process.stdout.write("AssetPress version " + info.version + "\n");
}

// And all flags
require("./assetpress")({
    verbose: argv.verbose || argv.v,
    clean: argv.clean || argv.c,
    inputDirectory: _.isString(argv.input) ? argv.input : argv._.length ? argv._[0] : void 0,
    outputDirectory: _.isString(argv.output || argv.o) ? argv.output || argv.o : void 0,
    os: argv.ios || argv.i ? "ios" : argv.android || argv.a ? "android" : void 0,
    screensDirectory: _.isString(argv.screens || argv.s) ? argv.screens || argv.s : void 0,
    skipResize: argv["skip-resize"],
    iosMinimum: argv["ios-min"],
    iosMaximum: argv["ios-max"],
    iosMinimumPhone: argv["ios-min-phone"],
    iosMaximumPhone: argv["ios-max-phone"],
    iosMinimumPad: argv["ios-min-pad"],
    iosMaximumPad: argv["ios-max-pad"],
    iosXcassets: argv["ios-xcassets"] || argv.x,
    androidLdpi: argv["android-ldpi"],
    androidXxxhdpi: argv["android-xxxhdpi"],
    workflowObject: argv.workflow,
    gitMessage: argv["git-message"] || argv.m,
    gitRoot: argv["git-root"],
    gitBranch: argv["git-branch"],
    gitPrefix: argv["git-prefix"],
    gitRemote: argv["git-remote"],
    gitNoPush: argv["git-no-push"]
});  //!/usr/bin/env node
