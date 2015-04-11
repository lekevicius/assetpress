path = require 'path'
fs = require 'fs-extra'

walk = require 'walkdir'

# resolvePath works very similarly to path.resolves, but handles ~ as user's home directory.
module.exports.resolvePath = (passedFrom, passedString) ->
  [ from, string ] = if passedString then [ passedFrom, passedString ] else [ false, passedFrom ]
  tilded = if string.substr(0,1) is '~' then process.env.HOME + string.substr(1) else string
  if from then return path.resolve(from, tilded) else path.resolve(tilded)

# Utility to escape shell command parameters
module.exports.escapeShell = (cmd) -> cmd.replace /(["\s'$`\\])/g, '\\$1'

# Utilities for working with paths.
module.exports.addTrailingSlash = (str) -> if str.slice(-1) isnt '/' then str + '/' else str
module.exports.removeTrailingSlash = (str) -> str.replace /\/$/, ""

module.exports.cleanMove = (from, to) ->
  # Many modules have 'clean' option.
  # Clean move deletes output directory and moves temporary output into its place.
  # This makes sure that no old-and-removed assets remain.
  file.removeSync to
  fs.mkdirpSync path.resolve(to, '..')
  fs.renameSync from, to
  
module.exports.dirtyMove = (from, to) ->
  # So-called dirty (non-clean) move goes file-by-file, not deleting any existing files.
  # Updated images are updated, added are added, removed are kept.
  # This is a conservative choice, but it does make sense to run with --clean from time to time.
  paths = walk.sync from
  for path in paths
    filepath = path.relative from, path
    fromPath = path.relative to, path
    toPath = path.resolve to, filepath
    toPathDir = path.parse(toPath).dir
    console.log path, filepath, fromPath, toPath, toPathDir
    fs.mkdirpSync toPathDir
    fs.renameSync fromPath, toPath

module.exports.move = (from, to, clean) ->
    moveFunction = if clean then module.exports.cleanMove else module.exports.dirtyMove
    moveFunction from, to
