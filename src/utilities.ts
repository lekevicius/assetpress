import * as path from 'path'
import * as fs from 'fs-extra'
import * as walk from 'walkdir'

export function resolvePath (passedFrom: string = '', passedString: string = '') {
  let from = passedString ? passedFrom : false
  let string = passedString ? passedString : passedFrom
  let tilded = string.substring(0, 1) === '~' ? process.env.HOME + string.substring(1) : string
  if (from) {
    return path.resolve(from, tilded)
  } else {
    return path.resolve(tilded)
  }
}

export function escapeShell(cmd: string) {
  return cmd.replace(/(["\s'$`\\])/g, '\\$1');
}

export function addTrailingSlash(str: string) {
  if (str.slice(-1) !== '/') {
    return str + '/'
  } else {
    return str
  }
}

export function removeTrailingSlash(str: string) {
  return str.replace(/\/$/, "")
}

export function cleanMove(from: string, to: string) {
  if (fs.existsSync(to)) {
    fs.removeSync(to)
  }
  fs.mkdirpSync(path.resolve(to, '..'))
  fs.renameSync(from, to)
}

export function dirtyMove (from: string, to: string) {
  let paths = walk.sync(from);
  let results: string[] = []
  paths.forEach((directoryPath: any) => {
    let filepath = path.relative(from, directoryPath)
    let fromPath = path.resolve(from, filepath)
    if (!fs.lstatSync(fromPath).isFile()) {
      return
    }
    let toPath = path.resolve(to, filepath)
    let toPathDir = path.parse(toPath).dir
    fs.mkdirpSync(toPathDir)
    results.push(fs.renameSync(fromPath, toPath))
  });
  for (let i = 0, len = paths.length; i < len; i++) {
    let directoryPath = paths[i];
  }
  results
}

export function move(from: string, to: string, clean: boolean) {
  let moveFunction = clean ? cleanMove : dirtyMove;
  moveFunction(from, to)
}
