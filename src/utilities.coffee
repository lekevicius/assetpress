path = require 'path'

module.exports.resolvePath = (string, from=false) ->
  tilded = if string.substr(0,1) is '~' then process.env.HOME + string.substr(1) else string
  if from then return path.resolve(from, tilded) else path.resolve(tilded)

module.exports.escapeShell = (cmd) -> cmd.replace /(["\s'$`\\])/g, '\\$1'

module.exports.addTrailingSlash = (str) -> if str.slice(-1) isnt '/' then str + '/' else str
module.exports.removeTrailingSlash = (str) -> str.replace /\/$/, ""
