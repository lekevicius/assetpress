childProcess = require 'child_process'

_ = require 'lodash'
shell = require 'shelljs'

util = require '../utilities'

options = 
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
    console.log "ERROR: git root directory is required."
    return callback()
    
  unless shell.which('git')
    console.log "ERROR: git is not installed."
    return callback()
    
  gitRootPath = util.resolvePath directory
  gitWorkTree = util.escapeShell util.addTrailingSlash(gitRootPath)
  gitDir = util.escapeShell gitWorkTree + '.git'
  shell.cd gitRootPath
  
  if options.branch
    shell.exec "git --git-dir=#{ gitDir } --work-tree=#{ gitWorkTree } checkout #{ options.branch }", { silent: !options.verbose }, (code, output) ->
      commitInsideBranch gitDir, gitWorkTree, message, callback
  else
    commitInsideBranch gitDir, gitWorkTree, message, callback

commitInsideBranch = (gitDir, gitWorkTree, message, callback) ->

  shell.exec "git --git-dir=#{ gitDir } --work-tree=#{ gitWorkTree } pull", { silent: !options.verbose }, (code, output) ->

    shell.exec "git --git-dir=#{ gitDir } --work-tree=#{ gitWorkTree } add -A .", { silent: !options.verbose }, (code, output) ->

      if _.isString(options.prefix) and options.prefix.length
        messageFlag = "-m '#{ options.prefix }#{ if message then ': ' + message else '' }'"
      else
        if message then messageFlag = "-m '#{ message }'" else messageFlag = ""

      shellOutput = shell.exec "git --git-dir=#{ gitDir } --work-tree=#{ gitWorkTree } commit #{ messageFlag }", { silent: !options.verbose }, (code, output) ->
        
        logMessage = "Commited to git #{ if messageFlag.length then 'with a message ' + messageFlag.substring(3) else 'witouth a message' }"
        
        unless options.noPush
          shell.exec "git --git-dir=#{ gitDir } --work-tree=#{ gitWorkTree } push #{ options.remote } #{ options.branch }", { silent: !options.verbose }, (code, output) ->
            shell.echo(logMessage) if options.verbose
            callback()
        else
          shell.echo(logMessage) if options.verbose
          callback()
  