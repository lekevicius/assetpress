var fs, path, walk;

path = require("path");
fs = require("fs-extra");

walk = require("walkdir");

// resolvePath works very similarly to path.resolves, but handles ~ as user's home directory.
module.exports.resolvePath = (passedFrom : any = "", passedString : any = false) => {
    var from, string, tilded, _ref, _ref1;
    if (passedString) {
        _ref = [passedFrom, passedString], from = _ref[0], string = _ref[1];
    } else {
        _ref1 = [false, passedFrom], from = _ref1[0], string = _ref1[1];
    }
    tilded = string.substring(0, 1) === "~" ? process.env.HOME + string.substring(1) : string;
    if (from) {
        return path.resolve(from, tilded);
    } else {
        return path.resolve(tilded);
    }
};

// Utility to escape shell command parameters
module.exports.escapeShell = (cmd) => cmd.replace(/(["\s'$`\\])/g, "\\$1");

// Utilities for working with paths.
module.exports.addTrailingSlash = (str) => {
    if (str.slice(-1) !== "/") {
        return str + "/";
    } else {
        return str;
    }
};
module.exports.removeTrailingSlash = (str) => str.replace(/\/$/, "");

module.exports.cleanMove = (from, to) => {
    // Many modules have 'clean' option.
    // Clean move deletes output directory and moves temporary output into its place.
    // This makes sure that no old-and-removed assets remain.
    if (fs.existsSync(to)) {
        fs.removeSync(to);
    }
    fs.mkdirpSync(path.resolve(to, ".."));
    return fs.renameSync(from, to);
};

module.exports.dirtyMove = (from, to) => {
    // So-called dirty (non-clean) move goes file-by-file, not deleting any existing files.
    // Updated images are updated, added are added, removed are kept.
    // This is a conservative choice, but it does make sense to run with --clean from time to time.
    var directoryPath, filepath, fromPath, paths, toPath, toPathDir, _i, _len, _results;
    paths = walk.sync(from);
    _results = [];
    for (_i = 0, _len = paths.length; _i < _len; _i++) {
        directoryPath = paths[_i];
        filepath = path.relative(from, directoryPath);
        fromPath = path.resolve(from, filepath);
        if (!fs.lstatSync(fromPath).isFile()) {
            continue;
        }
        toPath = path.resolve(to, filepath);
        toPathDir = path.parse(toPath).dir;
        fs.mkdirpSync(toPathDir);
        _results.push(fs.renameSync(fromPath, toPath));
    }
    return _results;
};

module.exports.move = (from, to, clean) => {
    var moveFunction;
    moveFunction = clean ? module.exports.cleanMove : module.exports.dirtyMove;
    return moveFunction(from, to);
};
