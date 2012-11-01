# Copyright (C) 2012	Saleem Abdul Hamid
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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.	If not, see <http://www.gnu.org/licenses/>.
#
# Some portions Copyright (C) 2012 Koding, Inc. under the MIT License
# http://www.opensource.org/licenses/mit-license.php
#

# base refers to js files that are referenced from the base dir path defined server-side- generally not packaged mundles
# mundle refers to js files that are in packaged mundles installed in the mundles directory by `mundle install`
basePrefix = '/b'
mundlePrefix = '/m'

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
		return module.exports
	
	# If module has not been fetched, fetch it and all its dependencies asynchronously and execute just it immediately, then callback its exports
	# If module has been fetched but not executed, execute it, then return and callback its exports
	# If module has already been executed, just return and callback its exports
	require:(path, callback)->
		if /^(\.|\.\.)?\//.test path
			path = resolveBasePath path, parent @path
			requireBase path, callback
		else
			path = resolveMundlePath path
			requireMundle path, callback


baseModule = (new Module "#{basePrefix}/")
# The var require here was added for testing in node.js to override node's require
window.require = require = baseModule.require.bind baseModule

requestHostname = window.location.hostname
requestPort = window.location.port

# xhr request to server
# looks like: http://<location.hostname>:<location.port>/mundlejs</file requested>?alreadyLoadedModule=1&anotherAlreadyLoaded=1&.....
serverRequire = (path, callback)->
	request = new XMLHttpRequest()
	request.open('GET', "//#{requestHostname}:#{requestPort}/mundlejs#{path}?#{cacheDiffString()}", true)
	# request.setRequestHeader 'clientid', 'lakjsdflkjasld'
	request.responseType = 'text'
	request.onload = ->
		response = JSON.parse request.response
		callback response.err, response.results
	request.send()

##
# Utils
##

requireBase = (path, callback)->
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
		serverRequire path, (errors, sources)=>
			# console.log path
			# console.log Object.keys sources
			if errors?
				for err in errors when err?
					console.warn err
			for own subPath, source of sources
				cache.fetched[subPath] = source
			callback? null, requireBase path
	
requireMundle = (path, callback)->
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
		serverRequire path, (errors, sources)=>
			# console.log path
			# console.log Object.keys sources
			if errors?
				for err in errors when err?
					console.warn err
			for own subPath, source of sources
				cache.fetched[subPath] = source
				cacheVersion subPath
			path = updateMundleVersion path
			callback? null, requireMundle path
 
# All paths get resolved to 'absolute' paths from the client-side 'root' with either a '/m/' or '/b/' prefix.
# /m is the path to installed mundles
# /b is the base path set on the server-side component
# relative path, e.g. '../foo.js' in a file at '/b/foo/bar/bar.js' resolves to '/b/foo/foo.js'
# "absolute" path, e.g. '/foo.js' resolves to '/b/foo.js'
# mundle name, e.g. 'foo' resolves to '/m/foo'
resolveBasePath = (path, parentPath)->
	# absolute paths
	if /^\//.test path
		return path = "#{basePrefix}#{path}"
	# relative paths
	else
		components = path.split '/'
		path = parentPath
		while components.length > 0
			switch component = (components.splice 0, 1)[0]
				when '..'
					path = parent path
				when '.'
				else
					path += "/#{component}"
		return path
	
resolveMundlePath = (path)->
	match = /^(.*?)((@)(.*?))?(\/.*)?$/.exec path
	version = match[4] or cache.versions[match[1]] or '0.0.0'
	path = "#{mundlePrefix}/#{match[1]}/#{version}"
	if (subDir = match[5])?
		path += subDir
	path
	
updateMundleVersion = (path)->
	match = /^(\/m\/(.*?)\/)(.*?)(\/.*)?$/.exec path
	if (version = match[3]) is '0.0.0'
		version = cache.versions[match[2]] or '0.0.0'
	path = match[1]+version
	if (subDir = match[4])?
		path += subDir
	path

parent = (path)->
	ar = path.split '/'
	console.error 'parent only accepts absolute paths' unless ar[0] is ''
	if ar[1] is 'm'
		if ar.length < 5 # []/[m]/[moduleName]/[version]/
			return ar.join '/'
	else if ar.length < 3 # []/[b]/
		return ar.join '/'
	ar.pop()
	ar.join '/'

cacheDiffString = ->
	((Object.keys cache.fetched).join '=1&') + '=1'

cacheVersion = (path)->
	if (match = /\/m\/(.*?)\/(.*?)(\/.*)?$/.exec path)?
		[match, mundle, version] = match
		cache.versions[mundle] = version

# modules - {file:reference to exports from already executed files}
# fetched - {file:string of the text of an already fetched file}
cache =
	modules : {}
	fetched : {}
	versions : {}
