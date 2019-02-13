"use strict";
var path = require("path");
var fs = require("fs-extra");
function resolvePath(passedFrom, passedString) {
    if (passedFrom === void 0) { passedFrom = ''; }
    if (passedString === void 0) { passedString = false; }
    var from, ref, ref1, string, tilded;
    if (passedString) {
        ref = [passedFrom, passedString], from = ref[0], string = ref[1];
    }
    else {
        ref1 = [false, passedFrom], from = ref1[0], string = ref1[1];
    }
    tilded = string.substring(0, 1) === '~' ? process.env.HOME + string.substring(1) : string;
    if (from) {
        return path.resolve(from, tilded);
    }
    else {
        return path.resolve(tilded);
    }
}
exports.resolvePath = resolvePath;
;
function escapeShell(cmd) {
    return cmd.replace(/(["\s'$`\\])/g, '\\$1');
}
exports.escapeShell = escapeShell;
;
function addTrailingSlash(str) {
    if (str.slice(-1) !== '/') {
        return str + '/';
    }
    else {
        return str;
    }
}
exports.addTrailingSlash = addTrailingSlash;
;
function removeTrailingSlash(str) {
    return str.replace(/\/$/, "");
}
exports.removeTrailingSlash = removeTrailingSlash;
;
function cleanMove(from, to) {
    if (fs.existsSync(to)) {
        fs.removeSync(to);
    }
    fs.mkdirpSync(path.resolve(to, '..'));
    return fs.renameSync(from, to);
}
exports.cleanMove = cleanMove;
;
function dirtyMove(from, to) {
    var directoryPath, filepath, fromPath, i, len, paths, results, toPath, toPathDir;
    paths = walk.sync(from);
    results = [];
    for (i = 0, len = paths.length; i < len; i++) {
        directoryPath = paths[i];
        filepath = path.relative(from, directoryPath);
        fromPath = path.resolve(from, filepath);
        if (!fs.lstatSync(fromPath).isFile()) {
            continue;
        }
        toPath = path.resolve(to, filepath);
        toPathDir = path.parse(toPath).dir;
        fs.mkdirpSync(toPathDir);
        results.push(fs.renameSync(fromPath, toPath));
    }
    return results;
}
exports.dirtyMove = dirtyMove;
;
function move(from, to, clean) {
    var moveFunction = clean ? cleanMove : dirtyMove;
    return moveFunction(from, to);
}
exports.move = move;
;
//# sourceMappingURL=utilities.js.map