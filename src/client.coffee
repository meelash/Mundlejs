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

# Each file that is loaded is evaluated in the context of a new Module instance
# Each instance has the variables module, exports, and require in scope
# module is a reference to the module instance for that file
# exports is the exports object which can be changed in the initial evaluation of the file to define the module api
# require will require a new file (with the option of a relative path, relative to the parent of this file)
class Module
  constructor:(@path)->
    @exports = {}
  
  runInContext:(source)->
    module = @
    exports = module.exports
    require = module.require.bind module
    eval source
    module.exports
  
  # If module has not been fetched, fetch it and all its dependencies asynchronously and execute just it immediately, then callback its exports
  # If module has been fetched but not executed, execute it, then return and callback its exports
  # If module has already been executed, just return and callback its exports
  require:(path, callback)->
    path = @resolvePath path
    if (exported = cache.modules[path])?
      callback? null, exported
      return exported
    else if (source = cache.fetched[path])?
      do ->
        module = new Module path
        exported = cache.modules[path] = module.runInContext source
        callback? null, exported
        return exported
    else
      serverRequire path, (errors, sources)->
        # console.log path
        # console.log Object.keys sources
        if errors?
          for err in errors when err?
            console.warn err
        for own subPath, source of sources
          cache.fetched[subPath] = source
          cache.cached[subPath] = yes
        callback? null, require path
 
  # All paths get resolved to 'absolute' paths from the client-side 'root' which is the base path set on the server-side component 
  resolvePath:(path)->
    if /^(.|..)\//.test path
      components = path.split '/'
      path = parent @path
      while components.length > 0
        switch component = (components.splice 0, 1)[0]
          when '..'
            path = parent path
          when '.'
          else
            path += "/#{component}"
    else if /^\//.test path
      path
    else
      path = "/#{path}.js"
    path

  parent = (path)->
    ar = path.split '/'
    ar.pop()
    ar.join '/'

baseModule = (new Module '')
window.require = baseModule.require.bind baseModule

requestHostname = window.location.hostname
requestPort = window.location.port
requestPath = ''

window.require.setRequestPath = (path)->
  requestPath = path.replace /^\//, ''

# xhr request to server
# looks like: http://<location.hostname>:<location.port>/<requestPath></file requested>?alreadyLoadedModule=1&anotherAlreadyLoaded=1&.....
serverRequire = (path, callback)->
  request = new XMLHttpRequest()
  request.open('GET', "http://#{requestHostname}:#{requestPort}/#{requestPath}#{path}?#{cacheDiffString()}", true)
  request.setRequestHeader 'clientid', 'lakjsdflkjasld'
  request.responseType = 'text'
  request.onload = ->
    response = JSON.parse request.response
    callback response.err, response.results
  request.send()

cacheDiffString = ->
  ((Object.keys cache.cached).join '=1&') + '=1'

# modules - {file:reference to exports from already executed files}
# fetched - {file:string of the text of an already fetched file}
# cached - {file:boolean whether it has been fetched or not}
cache =
  modules : {}
  fetched : {}
  cached  : {}
