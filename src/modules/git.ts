var childProcess, commitInsideBranch, defaults, options, shell, util;

childProcess = require('child_process');

import _ = require('lodash')

shell = require('shelljs');

util = require('../utilities');

options = defaults = {
  verbose: false,
  branch: '',
  remote: 'origin',
  prefix: 'Resource update',
  noPush: false
};

module.exports = function(directory, message, passedOptions, callback) {
  var gitDir, gitRootPath, gitWorkTree;
  if (message == null) {
    message = '';
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
  if (!directory) {
    console.log("ERROR: git root directory is required.");
    return callback();
  }
  if (!shell.which('git')) {
    console.log("ERROR: git is not installed.");
    return callback();
  }
  gitRootPath = util.resolvePath(directory);
  gitWorkTree = util.escapeShell(util.addTrailingSlash(gitRootPath));
  gitDir = util.escapeShell(gitWorkTree + '.git');
  shell.cd(gitRootPath);
  if (options.branch) {
    return shell.exec("git --git-dir=" + gitDir + " --work-tree=" + gitWorkTree + " checkout " + options.branch, {
      silent: !options.verbose
    }, function(code, output) {
      return commitInsideBranch(gitDir, gitWorkTree, message, callback);
    });
  } else {
    return commitInsideBranch(gitDir, gitWorkTree, message, callback);
  }
};

commitInsideBranch = function(gitDir, gitWorkTree, message, callback) {
  return shell.exec("git --git-dir=" + gitDir + " --work-tree=" + gitWorkTree + " pull", {
    silent: !options.verbose
  }, function(code, output) {
    return shell.exec("git --git-dir=" + gitDir + " --work-tree=" + gitWorkTree + " add -A .", {
      silent: !options.verbose
    }, function(code, output) {
      var messageFlag, shellOutput;
      if (_.isString(options.prefix) && options.prefix.length) {
        messageFlag = "-m '" + options.prefix + (message ? ': ' + message : '') + "'";
      } else {
        if (message) {
          messageFlag = "-m '" + message + "'";
        } else {
          messageFlag = "";
        }
      }
      return shellOutput = shell.exec("git --git-dir=" + gitDir + " --work-tree=" + gitWorkTree + " commit " + messageFlag, {
        silent: !options.verbose
      }, function(code, output) {
        var logMessage;
        logMessage = "Commited to git " + (messageFlag.length ? 'with a message ' + messageFlag.substring(3) : 'witouth a message');
        if (!options.noPush) {
          return shell.exec("git --git-dir=" + gitDir + " --work-tree=" + gitWorkTree + " push " + options.remote + " " + options.branch, {
            silent: !options.verbose
          }, function(code, output) {
            if (options.verbose) {
              shell.echo(logMessage);
            }
            return callback();
          });
        } else {
          if (options.verbose) {
            shell.echo(logMessage);
          }
          return callback();
        }
      });
    });
  });
};
