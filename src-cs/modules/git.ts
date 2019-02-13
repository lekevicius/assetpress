var childProcess, defaults, options, shell, util, _;

childProcess = require("child_process");

_ = require("lodash");
shell = require("shelljs");

util = require("../utilities");

options = defaults = {
    verbose: false,
    branch: "",
    remote: "origin",
    prefix: "Resource update",
    noPush: false
};

module.exports = (directory, message : any = "", passedOptions : any = {}, callback : any = false) => {
    var gitDir, gitRootPath, gitWorkTree;
    options = _.defaults(passedOptions, defaults);
    if (!callback) {
        function callback() {}  // noop
    }

    if (!directory) {
        console.log("ERROR: git root directory is required.");
        return callback();
    }

    if (!shell.which("git")) {
        console.log("ERROR: git is not installed.");
        return callback();
    }

    gitRootPath = util.resolvePath(directory);
    gitWorkTree = util.escapeShell(util.addTrailingSlash(gitRootPath));
    gitDir = util.escapeShell(gitWorkTree + ".git");
    shell.cd(gitRootPath);

    if (options.branch) {
        return shell.exec("git --git-dir=" + gitDir + " --work-tree=" + gitWorkTree + " checkout " + options.branch, {
            silent: !options.verbose
        }, (code, output) => commitInsideBranch(gitDir, gitWorkTree, message, callback));
    } else {
        return commitInsideBranch(gitDir, gitWorkTree, message, callback);
    }
};

function commitInsideBranch(gitDir, gitWorkTree, message, callback) {
    return shell.exec("git --git-dir=" + gitDir + " --work-tree=" + gitWorkTree + " pull", {
        silent: !options.verbose
    }, (code, output) => shell.exec("git --git-dir=" + gitDir + " --work-tree=" + gitWorkTree + " add -A .", {
            silent: !options.verbose
        }, (code, output) => {
            var messageFlag, shellOutput;
            if (_.isString(options.prefix) && options.prefix.length) {
                messageFlag = "-m '" + options.prefix + (message ? ": " + message : "") + "'";
            } else {
                if (message) {
                    messageFlag = "-m '" + message + "'";
                } else {
                    messageFlag = "";
                }
            }

            return shellOutput = shell.exec("git --git-dir=" + gitDir + " --work-tree=" + gitWorkTree + " commit " + messageFlag, {
                silent: !options.verbose
            }, (code, output) => {
                var logMessage;
                logMessage = "Commited to git " + (messageFlag.length ? "with a message " + messageFlag.substring(3) : "witouth a message");

                if (!options.noPush) {
                    return shell.exec("git --git-dir=" + gitDir + " --work-tree=" + gitWorkTree + " push " + options.remote + " " + options.branch, {
                        silent: !options.verbose
                    }, (code, output) => {
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
        }));
}
