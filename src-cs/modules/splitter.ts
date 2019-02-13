var defaults, fs, options, path, temporaryDirectory, tmp, util, walk, _;

fs = require("fs-extra");
path = require("path");

_ = require("lodash");
walk = require("walkdir");
tmp = require("temporary");

util = require("../utilities");

temporaryDirectory = "";
options = {};

defaults = {
    verbose: false,
    clean: false
};

module.exports = (source : any = process.cwd(), resourcesDestination : any = "./resources", screensDestination : any = "./screens", passedOptions : any = {}, callback : any = false) => {
    var resourcesDestinationDirectory, screensDestinationDirectory, sourceDirectory, temporaryDirectoryObject, tmpResourcesDirectory, tmpScreensDirectory;
    options = _.defaults(passedOptions, defaults);
    if (!callback) {
        function callback() {}  // noop
    }

    // Making all paths absolute
    sourceDirectory = util.resolvePath(source);
    resourcesDestinationDirectory = util.resolvePath(source, resourcesDestination);
    screensDestinationDirectory = util.resolvePath(source, screensDestination);

    temporaryDirectoryObject = new tmp.Dir;
    temporaryDirectory = temporaryDirectoryObject.path;
    temporaryDirectory = util.addTrailingSlash(temporaryDirectory);

    tmpResourcesDirectory = temporaryDirectory + "resources";
    tmpScreensDirectory = temporaryDirectory + "screens";

    fs.mkdirsSync(tmpResourcesDirectory);
    fs.mkdirsSync(tmpScreensDirectory);

    fs.readdirSync(sourceDirectory).forEach((filename) => {
        // The magic of splitter: moves everything named starting with <NUMBER>.<NUMBER> to screens, anything else to resources
        if (/^(\d+)\.(\d+)/.test(filename)) {
            fs.renameSync(path.resolve(sourceDirectory, filename), path.resolve(tmpScreensDirectory, filename));
            if (options.verbose) {
                return process.stdout.write("Screen " + filename + " moved.\n");
            }
        } else {
            fs.renameSync(path.resolve(sourceDirectory, filename), path.resolve(tmpResourcesDirectory, filename));
            if (options.verbose) {
                return process.stdout.write("Image " + filename + " moved.\n");
            }
        }
    });

    util.move(tmpResourcesDirectory, resourcesDestinationDirectory, options.clean);
    util.move(tmpScreensDirectory, screensDestinationDirectory, options.clean);

    fs.removeSync(temporaryDirectory);

    return callback();
};
