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

fs = require 'fs'
findRequires = require 'find-requires'

cachedPkgs = {}
loaded = {}
queue = 0

serverRequire = (path, loadedModules, callback)->
  loaded = loadedModules
  queue = 0
  results = {}
  errors = null
  readAndParseFile path, (err, path, contents)->
    results[path] = contents
    (errors or=[]).push err if err
    if queue is 0
      callback errors, results

readAndParseFile = (path, callback)->
  return if loaded[path]
  queue++
  try
    contents = fs.readFileSync (resolvePath path), 'utf8'
    loaded[path] = yes
    findAndLoadSyncRequires contents, callback
    queue--
    callback null, path, contents
  catch err
    queue--
    callback err, path, ''

findAndLoadSyncRequires = (contents, callback)->
  dependencies = findRequires contents, raw : yes
  for dependency in dependencies
    if (syncRequire = dependency.value)?
      readAndParseFile syncRequire, callback

resolvePath = (path)->
  "./#{path}"

cachePath = (path)->
  

module.exports = serverRequire
