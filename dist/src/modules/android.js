"use strict";
fs = require('fs-extra');
path = require('path');
_ = require('lodash');
im = require('gm').subClass({
    imageMagick: true
});
async = require('async');
tmp = require('temporary');
androidConstants = require('./android-constants');
util = require('../utilities');
defaults = {
    ldpi: false,
    xxxhdpi: false
};
inputDirectory = '';
outputDirectory = '';
temporaryDirectory = '';
temporaryPartsDirectory = '';
options = {};
processImage = function (task, callback) {
    var basename, filepath, image;
    filepath = task.path;
    basename = path.basename(filepath);
    image = im(filepath);
    return image.size(function (err, size) {
        var file;
        file = {
            filepath: filepath,
            basename: basename,
            filetype: path.extname(filepath).slice(1),
            density: task.density,
            scaleFactor: androidConstants.densities[task.density] / 4.0,
            image: image,
            width: size.width,
            height: size.height
        };
        if (file.basename.match(/\.nodpi\./i)) {
            if (file.density === 'mdpi') {
                return processNoDpiImage(file, callback);
            }
            else {
                return callback();
            }
        }
        else if (file.basename.match(/\.9(@(\d+)x)?\./i)) {
            return process9PatchImage(file, callback);
        }
        else {
            return processStandardImage(file, callback);
        }
    });
};
createPatch = function (file, side, callback) {
    var cropHeight, cropWidth, ref, ref1, ref2, ref3, resizeHeight, resizeWidth, x, y;
    if (side === 'top' || side === 'bottom') {
        cropWidth = file.width - file.patchScaleFactor * 2;
        cropHeight = 1;
        resizeWidth = Math.round(cropWidth * file.scaleFactor);
        resizeHeight = 1;
    }
    if (side === 'left' || side === 'right') {
        cropWidth = 1;
        cropHeight = file.height - file.patchScaleFactor * 2;
        resizeWidth = 1;
        resizeHeight = Math.round(cropHeight * file.scaleFactor);
    }
    switch (side) {
        case 'top':
            ref = [file.patchScaleFactor, file.patchScaleFactor - 1], x = ref[0], y = ref[1];
            break;
        case 'left':
            ref1 = [file.patchScaleFactor - 1, file.patchScaleFactor], x = ref1[0], y = ref1[1];
            break;
        case 'right':
            ref2 = [file.width - file.patchScaleFactor, file.patchScaleFactor], x = ref2[0], y = ref2[1];
            break;
        case 'bottom':
            ref3 = [file.patchScaleFactor, file.height - file.patchScaleFactor], x = ref3[0], y = ref3[1];
    }
    file[side + 'PatchPath'] = temporaryPartsDirectory + file.density + '-' + file.basename + '-' + side + 'Patch.png';
    return im(file.filepath).crop(cropWidth, cropHeight, x, y).antialias(false).filter('Point').resize(resizeWidth, resizeHeight, '!').write(file[side + 'PatchPath'], function (error) {
        if (error) {
            process.stdout.write(error);
        }
        return callback();
    });
};
createPatchContent = function (file, callback) {
    var cropHeight, cropWidth;
    cropWidth = file.width - file.patchScaleFactor * 2;
    cropHeight = file.height - file.patchScaleFactor * 2;
    file.patchContentWidth = Math.round(cropWidth * file.scaleFactor);
    file.patchContentHeight = Math.round(cropHeight * file.scaleFactor);
    file.contentPatchPath = temporaryPartsDirectory + file.density + '-' + file.basename + '-content.png';
    return im(file.filepath).crop(cropWidth, cropHeight, file.patchScaleFactor, file.patchScaleFactor).filter(androidConstants.resizeFilter).resize(file.patchContentWidth, file.patchContentHeight).write(file.contentPatchPath, function (error) {
        if (error) {
            process.stdout.write(error);
        }
        return callback();
    });
};
process9PatchImage = function (file, callback) {
    var fileDestination, scaledPatchInfo;
    scaledPatchInfo = file.basename.match(/\.9@(\d+)x\./i);
    if (scaledPatchInfo) {
        file.patchScaleFactor = parseInt(scaledPatchInfo[1]);
        file.basename = file.basename.replace(/\.9@(\d+)x\./i, '.9.');
    }
    else {
        file.patchScaleFactor = 1;
    }
    if ((file.width - file.patchScaleFactor * 2) % 4 !== 0 || (file.height - file.patchScaleFactor * 2) % 4 !== 0) {
        process.stdout.write("WARNING: Image " + file.basename + " dimensions are not multiples of 4. Skipping.\n");
        callback();
    }
    fileDestination = temporaryDirectory + 'drawable-' + file.density + '/' + file.basename;
    return createPatchContent(file, function () {
        return createPatch(file, 'left', function () {
            return createPatch(file, 'right', function () {
                return createPatch(file, 'top', function () {
                    return createPatch(file, 'bottom', function () {
                        var _composite;
                        _composite = im(file.patchContentWidth + 2, file.patchContentHeight + 2, '#ffffff00').out('-define', 'png:exclude-chunk=tIME,tEXt,zTXt,date');
                        _composite.draw(["image Over 1,1 0,0 \'" + file.contentPatchPath + "\'"]);
                        _composite.draw(["image Over 1,0 0,0 \'" + file.topPatchPath + "\'"]);
                        _composite.draw(["image Over 0,1 0,0 \'" + file.leftPatchPath + "\'"]);
                        _composite.draw(["image Over " + (file.patchContentWidth + 1) + ",1 0,0 \'" + file.rightPatchPath + "\'"]);
                        _composite.draw(["image Over 1," + (file.patchContentHeight + 1) + " 0,0 \'" + file.bottomPatchPath + "\'"]);
                        return _composite.write(fileDestination, function (error) {
                            if (error) {
                                process.stdout.write(error);
                            }
                            if (options.verbose) {
                                process.stdout.write("Saved " + file.basename + " in " + file.density + " density.\n");
                            }
                            return callback();
                        });
                    });
                });
            });
        });
    });
};
processStandardImage = function (file, callback) {
    var fileDestination;
    if (file.width % 4 !== 0 || file.height % 4 !== 0) {
        process.stdout.write("WARNING: Image " + file.basename + " dimensions are not multiples of 4. Skipping.\n");
        return callback();
    }
    fileDestination = temporaryDirectory + 'drawable-' + file.density + '/' + file.basename;
    return file.image.out('-define', 'png:exclude-chunk=tIME,tEXt,zTXt,date').filter(androidConstants.resizeFilter).resize(Math.round(file.width * file.scaleFactor), Math.round(file.height * file.scaleFactor), '!').write(fileDestination, function (error) {
        if (error) {
            process.stdout.write(error);
        }
        if (options.verbose) {
            process.stdout.write("Saved  " + file.basename + " in " + file.density + " density.\n");
        }
        return callback();
    });
};
processNoDpiImage = function (file, callback) {
    var cleanBasename;
    fs.ensureDirSync(temporaryDirectory + 'drawable-nodpi');
    cleanBasename = file.basename.replace('.nodpi', '');
    return fs.copy(file.filepath, temporaryDirectory + 'drawable-nodpi/' + cleanBasename, function () {
        if (options.verbose) {
            process.stdout.write("Saved nodpi image " + file.basename + "\n");
        }
        return callback();
    });
};
function default_1(passedInputDirectory, passedOutputDirectory, passedOptions, callback) {
    var density, file, i, j, len, len1, outputDirectoryBase, outputDirectoryName, produceDensities, queue, ref, results, temporaryDirectoryObject, temporaryPartsDirectoryObject;
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
    passedInputDirectory = passedOutputDirectory;
    options = _.defaults(passedOptions, defaults);
    if (!callback) {
        callback = function () { };
    }
    outputDirectoryName = passedOutputDirectory ? util.removeTrailingSlash(passedOutputDirectory) : 'res';
    outputDirectoryBase = util.resolvePath(inputDirectory, '..');
    outputDirectory = util.addTrailingSlash(util.resolvePath(outputDirectoryBase, outputDirectoryName));
    temporaryDirectoryObject = new tmp.Dir;
    temporaryDirectory = util.addTrailingSlash(temporaryDirectoryObject.path);
    temporaryPartsDirectoryObject = new tmp.Dir;
    temporaryPartsDirectory = util.addTrailingSlash(temporaryPartsDirectoryObject.path);
    produceDensities = _.keys(androidConstants.densities);
    if (!options.ldpi) {
        produceDensities = _.without(produceDensities, 'ldpi');
    }
    if (!options.xxxhdpi) {
        produceDensities = _.without(produceDensities, 'xxxhdpi');
    }
    for (i = 0, len = produceDensities.length; i < len; i++) {
        density = produceDensities[i];
        fs.ensureDirSync(path.resolve(temporaryDirectory, "drawable-" + density));
    }
    queue = async.queue(processImage, 2);
    queue.drain = function () {
        var j, len1;
        for (j = 0, len1 = produceDensities.length; j < len1; j++) {
            density = produceDensities[j];
            util.move(path.resolve(temporaryDirectory, "drawable-" + density), path.resolve(outputDirectory, "drawable-" + density), options.clean);
        }
        fs.removeSync(temporaryPartsDirectory);
        fs.removeSync(temporaryDirectory);
        return callback();
    };
    ref = fs.readdirSync(inputDirectory);
    results = [];
    for (j = 0, len1 = ref.length; j < len1; j++) {
        file = ref[j];
        if (file.slice(0, 1) === '.' || file.slice(0, 1) === '_') {
            continue;
        }
        if (!fs.lstatSync(path.resolve(inputDirectory, file)).isFile()) {
            process.stdout.write("Android does not support nested resources. Skipping " + file + ".\n");
            continue;
        }
        if (!_.contains(androidConstants.allowedExtensions, path.extname(file))) {
            process.stdout.write("The format of " + file + "  is unsupported. Skipping.\n");
            continue;
        }
        results.push((function () {
            var k, len2, results1;
            results1 = [];
            for (k = 0, len2 = produceDensities.length; k < len2; k++) {
                density = produceDensities[k];
                results1.push(queue.push({
                    path: path.join(inputDirectory, file),
                    density: density
                }));
            }
            return results1;
        })());
    }
    return results;
}
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = default_1;
;
//# sourceMappingURL=android.js.map