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

requestHostname = window.location.hostname
requestPort = window.location.port
requestPath = ''

window.require = require = (path, callback)->
  if (exported = cache.modules[path])?
    callback? null, exported
    return exported
  else if (source = cache.fetched[path])?
    do ->
      module = exports : {}
      eval source
      exported = cache.modules[path] = module.exports
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

require.setBasePath = (path)->
  requestPath = path.replace /^\//, ''

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

cache =
  modules : {}
  fetched : {}
  cached  : {}