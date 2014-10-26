
fs = require 'fs'
path = require 'path'
{make_esc} = require 'iced-error'
log = require 'iced-logger'
minimist = require 'minimist'

#==================================================================

class File

  constructor : (@id, @path) ->

#==================================================================

class Indexer

  constructor : (@dir) ->
    @map = {}
    @ord = []

  _index : (d, cb) ->
    esc = make_esc cb, "Indexer.index"
    await fs.readdir d, esc defer files
    for file in files when not (file in [".", ".."])
      full = path.join(d, file)
      await fs.stat full, esc defer stat
      if stat.isDirectory()
        await @_index full, esc defer()
      else if file.match /^P[0-9]{7}\.(MOV|JPG|RW2)$/
        f = new File file, full
        @map[file] = f
        @ord.push file
    cb null

  index : (cb) ->
    @_index @dir, cb

#==================================================================

class Runner

  constructor : () ->

  #---------------------------

  index : (cb) ->
    esc = make_esc cb, "Runner::index"
    await @sd.index esc defer()
    await @archive.index esc defer()
    cb null

  #---------------------------

  parse_args : (cb) ->
    err = null
    @argv = minimist(process.argv[2...])
    if @argv._.length isnt 2
      err = new Error "need 2 arguments: <SD-dir> <photo-archive-dir>"
    else
      @sd = new Indexer @argv._[0]
      @archive = new Indexer @argv._[1]
    cb err  

  #---------------------------

  diff : (cb) ->
    miss = false
    for f in @sd.ord
      unless @archive.map[f]?
        console.log "M #{@sd.map[f].path}"
        miss = true
    err = if miss then (new Error "missing files!") else null
    cb err

  #---------------------------

  run : (cb) ->
    esc = make_esc cb, "Runner::run"
    await @parse_args esc defer()
    await @index esc defer()
    await @diff esc defer()
    cb null

#==================================================================

exports.main = main = () ->
  await (new Runner).run defer err
  log.error err.toString() if err?
  process.exit (if err? then -2 else 0)

#==================================================================
