childProcess = require 'child_process'

_ = require 'lodash'
shell = require 'shelljs'

util = require '../utilities'

defaults =
  verbose: false
  branch: ''
  remote: 'origin'
  prefix: 'Resource update'
  noPush: false

module.exports = (directory, message = '', passedOptions = {}, callback = false) ->
  
  options = _.defaults passedOptions, defaults
  unless callback then callback = -> # noop

  unless directory
    process.stdout.write "ERROR: git root directory is required.\n"
    return callback()
    
  unless shell.which('git')
    process.stdout.write "ERROR: git is not installed.\n"
    return callback()
    
  gitRootPath = util.resolvePath directory
  gitWorkTree = util.escapeShell util.addTrailingSlash(gitRootPath)
  gitDir = util.escapeShell gitWorkTree + '.git'
  
  if options.branch
    out = childProcess.spawnSync "git --git-dir=#{ gitDir } --work-tree=#{ gitWorkTree } checkout #{ options.branch }"
    console.log(out) if options.verbose

  out = childProcess.spawnSync "git --git-dir=#{ gitDir } --work-tree=#{ gitWorkTree } pull"
  console.log(out) if options.verbose
  out = childProcess.spawnSync "git --git-dir=#{ gitDir } --work-tree=#{ gitWorkTree } add -A ."
  console.log(out) if options.verbose

  if _.isString(options.prefix) and options.prefix.length
    messageFlag = "-m '#{ options.prefix }#{ if message then ': ' + message else '' }'"
  else
    if message then messageFlag = "-m '#{ message }'" else messageFlag = ""

  out = childProcess.spawnSync "git --git-dir=#{ gitDir } --work-tree=#{ gitWorkTree } commit #{ messageFlag }"
  console.log(out) if options.verbose
  unless options.noPush
    out = childProcess.spawnSync "git --git-dir=#{ gitDir } --work-tree=#{ gitWorkTree } push #{ options.remote } #{ options.branch }"
    console.log(out) if options.verbose

  process.stdout.write "Commited to git #{ if messageFlag.length then 'with a message ' + messageFlag.substring(3) else 'witouth a message' }\n" if options.verbose

  callback()
