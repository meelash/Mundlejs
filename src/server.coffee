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

fs = require 'fs'
path = require 'path'
url = require 'url'
findRequires = require 'find-requires'

pkgCache = {}
indexCache = {}
fileCache = {}
basePath = '/'
loadedPlugins = {}

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
				safePath = path
			results[safePath] = contents
			if err
				(errors or= {})[safePath] = err
				err.path = safePath
			if @queue is 0
				callback errors, results

	# recursively read and parse file and dependencies
	readAndParseFile:(path, parent, callback)->
		try
			# resolve client-side safe-path to server-side absolute path
			path = resolvePath path, parent
		catch err
			return callback.call @, err, path, ''

		return if @loaded[sanitizePath path]
		@queue++
		try
			contents = fileCache[sanitizePath path] or= fs.readFileSync (path), 'utf8'
			contents = processWithPlugins path, contents
			@loaded[sanitizePath path] = yes
			@findAndLoadSyncRequires path, contents, callback
			@queue--
			callback.call @, null, path, contents
		catch err
			@queue--
			{errno, code, syscall} = err
			console.error err
			error = {message : 'No such file or directory', errno, code, syscall}
			callback.call @, error, path, ''

	# parses a file for dependencies
	findAndLoadSyncRequires:(filePath, contents, callback)->
		dependencies = indexCache[sanitizePath filePath] or= findRequires contents, raw : yes
		for dependency in dependencies
			if (syncRequire = dependency.value)?
				@readAndParseFile syncRequire, (path.dirname filePath), callback

# utility to resolve relative paths from the client and block access below the base path
resolvePath = (relPath, parent)->
	# relative requires in the synchronous dependencies are handled in this branch
	# those in the asynchronous dependencies are made absolute client-side, pre-request
	if /^(.|..)\//.test relPath
		if parent
			absPath = path.join parent, relPath
		else
			absPath = path.join basePath, relPath
	
	# All asynchronous (client-side) requires will come to this branch, along with module-name require in the synchronous dependencies
	else
		absPath = path.join basePath, relPath
		
		# module-name requires in the synchronous dependencies
		unless /^\//.test relPath
			absPath += '.js'
	# security- ensure that it is never possible to get anything or see any server
	# paths above the client-root (basePath)
	if (sanitizePath absPath).length is 0
		throw {
			message : 'Attempt to access file above client-root'
			path		: relPath
		}
	else
		absPath

# utility to convert absolute paths to relative paths for syncing with the client
sanitizePath = (path)->
	sanitizedPath = ''
	re = new RegExp "(^#{basePath}\/*)(.*)"
	path.replace re, (str, p1, p2)->
		sanitizedPath = "/#{p2}"
	sanitizedPath

processWithPlugins = (filePath, contents)->
	extension = (path.extname filePath)[1..]
	if (compiler = loadedPlugins[extension])?
		contents = compiler contents
	contents

getPackageCache = (filePath, clientCacheDiff)->
	filePath = resolvePath filePath, basePath
	index = filePath + (Object.keys clientCacheDiff).sort()
	return pkgCache[index] or index

addPackageCache = (index, data)->
	pkgCache[index] = cache = new Buffer (JSON.stringify data)
	return cache
	
requestHandler = (req, res, next)->
	if req.url is '/mundlejs/require.js' 
		clientJs = fs.readFileSync "#{__dirname}/client.js"
		res.writeHead 200, 'Content-Type' : 'text/javascript'
		res.end clientJs
	else if (req.url.search /^\/mundlejs\//) isnt -1
		parsedUrl = url.parse req.url[9...], yes
		# if req.headers.clientid?
		filePath = '/' + parsedUrl.pathname[1...]
		clientCacheDiff = parsedUrl.query
		if (cache = getPackageCache filePath, clientCacheDiff) instanceof Buffer
			res.writeHead 200, 'Content-Type' : 'text/javascript', 'Content-Length' : cache.length
			res.end cache
		else
			cacheIndex = cache
			serverRequire filePath, clientCacheDiff, (err, results)->
				cache = addPackageCache cacheIndex, {err, results}
				res.writeHead 200, 'Content-Type' : 'text/javascript', 'Content-Length' : cache.length
				res.end cache
	else
		next?()

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
# relPath <String> the path, either absolute or relative from process.cwd()
serverRequire.setBasePath = (relPath)->
	basePath = path.resolve relPath

serverRequire.setBasePath './'

# serverRequire.listen(server)
# serverRequire.listen(port, options, callback)
# if a server is passed, start listening on that server
# if a port is passed, create a server with options and start it listening on that part, then callback
# server <HTTP(S)Server>
# port <Number>
# options <Object> options to be passed to http server
# callback <Function>
serverRequire.listen = (server, options, callback)->
	if 'function' is typeof options
		callback = options
		options = {}

	if 'undefined' is typeof server
		# create a server that listens on port 80
		server = 80

	if 'number' is typeof server
		# if a port number is passed
		port = server

		if options && options.key
			server = require('https').createServer options
		else
			server = require('http').createServer()
		
		# This server is just being used for mundle, so all non-mundle requests display this friendly message
		server.on 'request', (req, res)->
			if (req.url.search /^\/mundlejs\//) is -1
				res.writeHead 200
				res.end 'Welcome to Mundlejs!'

		server.listen port, callback

	server.on 'request', requestHandler
	return server

# Connect middleware
# serverRequire.connect(basePath)
# basePath <string> the base path relative to which all client-passed paths will be resolved
# see serverRequire.setBasePath for more information
serverRequire.connect = (basePath)->
	if basePath?
		serverRequire.setBasePath basePath
	requestHandler

# Add a plugin for pre-compiling files
# plugin <Object {extensions, compiler}> plugin defining the file extensions it should be applied to and the compiler it should run the text through.
serverRequire.use = (plugins)->
	plugins = [plugins] unless plugins instanceof Array
	for plugin in plugins
		{extensions, compiler} = plugin
		for extension in extensions
			loadedPlugins[extension] = compiler
	
module.exports = serverRequire
