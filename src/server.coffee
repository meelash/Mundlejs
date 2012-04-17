# Copyright (C) 2012  Saleem Abdul Hamid
# 
# This file is part of Mundlejs.
# 
# Mundlejs is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Some portions Copyright (C) 2012 Koding, Inc. under the MIT License
# http://www.opensource.org/licenses/mit-license.php
#

fs = require 'fs'
path = require 'path'
findRequires = require 'find-requires'

cachedPkgs = {}
basePath = '/'

# An instance of class Mundle is created for each client-side request
class Mundle
  constructor:(loadedModules)->
    @loaded = loadedModules
    @queue = 0
 
  # calls readAndParseFile and collects errors and file contents from it and the required file and all dependencies
  require:(path,callback)->
    results = {}
    errors = null
    @readAndParseFile path, basePath, (err, path, contents)->
      if (safePath = sanitizePath path).length is 0
        results[path] = contents
      else
        results[safePath] = contents
      (errors or=[]).push err if err
      if @queue is 0
        callback errors, results

  # recursively read and parse file and dependencies
  readAndParseFile:(path, parent, callback)->
    try
      path = resolvePath path, parent
    catch err
      return callback.call @, err, path, ''

    return if @loaded[sanitizePath path]
    @queue++
    try
      contents = fs.readFileSync (path), 'utf8'
      @loaded[sanitizePath path] = yes
      @findAndLoadSyncRequires path, contents, callback
      @queue--
      callback.call @, null, path, contents
    catch err
      @queue--
      callback.call @, err, path, ''

  # parses a file for dependencies
  findAndLoadSyncRequires:(filePath, contents, callback)->
    dependencies = findRequires contents, raw : yes
    for dependency in dependencies
      if (syncRequire = dependency.value)?
        @readAndParseFile syncRequire, (path.dirname filePath), callback

# utility to resolve relative paths from the client and block access below the base path
resolvePath = (relPath, parent)->
  if /^(.|..)\//.test relPath
    if parent
      absPath = path.join parent, relPath
    else
      absPath = path.join basePath, relPath
    if (sanitizePath absPath).length is 0
      throw 'Unauthorized attempt to access file'
    else
      absPath
  else
    absPath = path.join basePath, relPath
    unless /^\//.test relPath
      absPath += '.js'
  absPath

# utility to convert absolute paths to relative paths for syncing with the client
sanitizePath = (path)->
  sanitizedPath = ''
  re = new RegExp "(^#{basePath}\/*)(.*)"
  path.replace re, (str, p1, p2)->
    sanitizedPath = "/#{p2}"
  sanitizedPath

cachePath = (path)->

# API
#
# serverRequire(path, loadedModules, callback)
# path <string> path to file that you want to load along with its dependencies
# loadedModules <object> relativePath:boolean array of modules that have already been loaded
# callback <function(errors, modules)> array of errors and object with relative paths and contents of required file and all dependencies 
serverRequire = (path, loadedModules, callback)->
  mundle = new Mundle loadedModules
  mundle.require path, callback

# serverRequire.setBasePath(relPath)
# Set the base path relative to which all client-passed paths will be resolved.
# This is also the limit of client-side visibility, e.g. client cannot ever load a file '/..'
# This is the root as far as the client is concerned.
# Defaults to whatever directory serverRequire is run from. 
serverRequire.setBasePath = (relPath)->
  basePath = path.resolve relPath

serverRequire.setBasePath './'
  
module.exports = serverRequire
