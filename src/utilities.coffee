path = require 'path'

module.exports.resolvePath = (string, from=false) ->
  if from
    path.resolve( from, (if string.substr(0,1) is '~' then process.env.HOME + string.substr(1) else string ))
  else
    path.resolve( if string.substr(0,1) is '~' then process.env.HOME + string.substr(1) else string )

module.exports.escapeShell = (cmd) -> cmd.replace /(["\s'$`\\])/g, '\\$1'
