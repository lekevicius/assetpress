import * as fs from 'fs-extra'
import * as path from 'path'
import * as _ from 'lodash'

import * as async from 'async'
import * as tmp from 'temporary'
import * as shell from 'shelljs'

import androidResizer from './modules/android'
import iOSResizer from './modules/ios'
import splitter from './modules/splitter'

import git  from './modules/git'

import * as util from './utilities'

options = {};

interface GitOptions {
  gitMessage?: string
  gitRoot?: string
  gitBranch?: string
  gitPrefix?: string
  gitRemote?: string
  gitNoPush?: boolean
}

let defaults: any = {
  verbose: false,
  clean: false,
  inputDirectory: 'source',
  outputDirectory: false,
  os: 'ios',
  screensDirectory: false,
  skipResize: false,
  workflowObject: false,
  gitOptions?: new GitOptions
};

export default function(passedOptions: any, callback: Function) {
  options = _.defaults(passedOptions, defaults);
  if (!callback) {
    callback = function() {};
  }
  inputDirectory = util.resolvePath(options.inputDirectory);
  inputDetails = path.parse(inputDirectory);
  queue = async.queue(performWorkflow, 1);
  queue.drain = function() {};
  if (options.workflowObject || (inputDetails.ext.toLowerCase() === '.json' && _.endsWith(inputDetails.name.toLowerCase(), '.assetpress'))) {
    if (options.workflowObject) {
      if (_.isString(options.workflowObject)) {
        options.workflowObject = JSON.parse(options.workflowObject);
      }
      if (_.isArray(options.workflowObject)) {
        ref = options.workflowObject;
        for (i = 0, len = ref.length; i < len; i++) {
          singleObject = ref[i];
          singleObject.location = path.resolve('..');
        }
      } else {
        options.workflowObject.location = path.resolve('..');
      }
    } else {
      options.workflowObject = require(inputDirectory);
      if (_.isArray(options.workflowObject)) {
        ref1 = options.workflowObject;
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          singleObject = ref1[j];
          singleObject.location = inputDetails.dir;
        }
      } else {
        options.workflowObject.location = inputDetails.dir;
      }
    }
    if (_.isArray(options.workflowObject)) {
      ref2 = options.workflowObject;
      for (k = 0, len2 = ref2.length; k < len2; k++) {
        singleObject = ref2[k];
        singleObject.verbose = options.verbose;
      }
    } else {
      options.workflowObject.verbose = options.verbose;
    }
    if (_.isArray(options.workflowObject)) {
      ref3 = options.workflowObject;
      results = [];
      for (l = 0, len3 = ref3.length; l < len3; l++) {
        singleObject = ref3[l];
        results.push(queue.push(singleObject));
      }
      return results;
    } else if (_.isObject(options.workflowObject)) {
      return queue.push(options.workflowObject);
    }
  } else {
    workflowObject = {
      location: path.resolve('..'),
      verbose: options.verbose
    };
    workflowObject.source = inputDirectory;
    if (options.os === 'ios') {
      osKeys = ['iosMinimum', 'iosMaximum', 'iosMinimumPhone', 'iosMaximumPhone', 'iosMinimumPad', 'iosMaximumPad', 'iosXcassets'];
    } else {
      osKeys = ['androidLdpi', 'androidXxxhdpi'];
    }
    workflowObject.assetpress = _.pick(options, _.union(['verbose', 'os'], osKeys));
    if (options.skipResize) {
      delete workflowObject.assetpress;
    }
    if (options.screensDirectory) {
      workflowObject.screens = {
        destination: util.resolvePath(inputDetails.dir, options.screensDirectory),
        clean: options.clean
      };
    }
    workflowObject.output = {
      destination: options.outputDirectory,
      clean: options.clean
    };
    return queue.push(workflowObject);
  }
};

performWorkflow = function(workflowObject, callback) {
  var androidOptions, completeFunction, iosOptions, outputObject, screensObject, shellOutput, temporaryDirectory, temporaryDirectoryObject, temporarySourceDirectory;
  workflowObject.source = util.resolvePath(workflowObject.location, workflowObject.source);
  if (!fs.existsSync(workflowObject.source)) {
    process.stdout.write("Error: Source " + workflowObject.source + " does not exist.\n");
    return callback();
  }
  outputObject = {
    destination: util.resolvePath(workflowObject.source, "../" + (path.basename(workflowObject.source, '.sketch')) + " Resources"),
    suggestedDestination: true,
    clean: options.clean
  };
  if (workflowObject.output) {
    if (_.isString(workflowObject.output)) {
      outputObject = {
        destination: util.resolvePath(workflowObject.location, workflowObject.output),
        clean: options.clean
      };
    } else if (workflowObject.output.destination && _.isString(workflowObject.output.destination)) {
      outputObject = workflowObject.output;
      outputObject.destination = util.resolvePath(workflowObject.location, workflowObject.output.destination);
      if (!_.has(outputObject, 'clean')) {
        outputObject.clean = options.clean;
      }
    }
  }
  if (options.gitMessage) {
    outputObject.gitMessage = options.gitMessage;
  }
  workflowObject.output = outputObject;
  if (workflowObject.output.destination.indexOf(util.addTrailingSlash(workflowObject.source)) === 0) {
    process.stdout.write("ERROR: output destination is inside source.\n");
    return callback();
  }
  temporaryDirectoryObject = new tmp.Dir;
  temporaryDirectory = util.addTrailingSlash(temporaryDirectoryObject.path);
  temporarySourceDirectory = temporaryDirectory + 'source';
  if (fs.lstatSync(workflowObject.source).isDirectory()) {
    fs.copySync(workflowObject.source, temporarySourceDirectory);
  } else if (path.extname(workflowObject.source).toLowerCase() === '.sketch') {
    if (!shell.which('sketchtool')) {
      process.stdout.write("ERROR: Sketchtool is required. Download it from http://bohemiancoding.com/sketch/tool/\n");
      fs.removeSync(temporaryDirectory);
      return callback();
    }
    shellOutput = shell.exec("sketchtool export slices --output=" + (util.escapeShell(temporaryDirectory + 'source')) + " " + (util.escapeShell(workflowObject.source)), {
      silent: !workflowObject.verbose
    });
  } else {
    process.stdout.write("ERROR: AssetPress workflow currently only accepts directories and Sketch files as source.\n");
    fs.removeSync(temporaryDirectory);
    return callback();
  }
  if (workflowObject.screens) {
    screensObject = {
      source: temporarySourceDirectory,
      resourcesDestination: '.',
      screensDestination: util.resolvePath(workflowObject.source, '../Screen Previews'),
      options: {
        verbose: workflowObject.verbose,
        clean: false
      }
    };
    if (_.isString(workflowObject.screens)) {
      screensObject.screensDestination = util.resolvePath(workflowObject.location, workflowObject.screens);
    } else {
      screensObject.screensDestination = util.resolvePath(workflowObject.location, workflowObject.screens.destination);
      if (_.has(workflowObject.screens, 'clean')) {
        screensObject.options.clean = workflowObject.screens.clean;
      }
    }
    splitter(screensObject.source, screensObject.resourcesDestination, screensObject.screensDestination, screensObject.options);
    if (workflowObject.verbose) {
      process.stdout.write("Split screens to " + screensObject.screensDestination + ".\n");
    }
  }
  if (workflowObject.assetpress && _.isObject(workflowObject.assetpress)) {
    if (!workflowObject.assetpress.os) {
      process.stdout.write("WARNING: Running AssetPress with iOS implied. Please set 'os' value in assetpress object.\n");
      workflowObject.assetpress.os = 'ios';
    }
    if (workflowObject.assetpress.os === 'ios' && workflowObject.assetpress.iosXcassets && workflowObject.output.suggestedDestination) {
      workflowObject.output.destination = util.removeTrailingSlash(outputObject.destination) + '.xcassets';
    }
    completeFunction = function() {
      if (workflowObject.verbose) {
        process.stdout.write("Completed AssetPress for " + workflowObject.source + "\n");
      }
      return completeWorkflow(workflowObject, temporaryDirectory, callback);
    };
    switch (workflowObject.assetpress.os) {
      case 'android':
        androidOptions = {
          verbose: workflowObject.verbose,
          clean: workflowObject.output.clean,
          ldpi: workflowObject.assetpress.androidLdpi,
          xxxhdpi: workflowObject.assetpress.androidXxxhdpi
        };
        return androidResizer(temporarySourceDirectory, workflowObject.output.destination, androidOptions, completeFunction);
      case 'ios':
        iosOptions = {
          verbose: workflowObject.verbose,
          clean: workflowObject.output.clean,
          minimum: workflowObject.assetpress.iosMinimum,
          maximum: workflowObject.assetpress.iosMaximum,
          minimumPhone: workflowObject.assetpress.iosMinimumPhone,
          maximumPhone: workflowObject.assetpress.iosMaximumPhone,
          minimumPad: workflowObject.assetpress.iosMinimumPad,
          maximumPad: workflowObject.assetpress.iosMaximumPad,
          xcassets: workflowObject.assetpress.iosXcassets
        };
        return iOSResizer(temporarySourceDirectory, workflowObject.output.destination, iosOptions, completeFunction);
    }
  } else {
    if (!outputObject.suggestedDestination) {
      util.move(temporarySourceDirectory, workflowObject.output.destination, workflowObject.output.clean);
      if (workflowObject.verbose) {
        process.stdout.write("Moved output to " + to.destination + "\n");
      }
      return completeWorkflow(workflowObject, temporaryDirectory, callback);
    } else {
      fs.removeSync(temporaryDirectory);
      return callback();
    }
  }
};

completeWorkflow = function(workflowObject, temporaryDirectory, callback) {
  var gitOptions;
  fs.removeSync(temporaryDirectory);
  if (workflowObject.output.gitRoot) {
    gitOptions = {
      verbose: workflowObject.verbose,
      branch: workflowObject.output.gitBranch,
      prefix: workflowObject.output.gitPrefix,
      remote: workflowObject.output.gitRemote,
      noPush: workflowObject.output.gitNoPush
    };
    return git(workflowObject.output.gitRoot, workflowObject.output.gitMessage, gitOptions, callback);
  } else {
    return callback();
  }
};
