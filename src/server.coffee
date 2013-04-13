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
packageCache = {}
basePath = '/'
mundlesPath = path.resolve './mundles'
loadedPlugins = {}

# If obj.hasOwnProperty has been overridden, then calling
# obj.hasOwnProperty(prop) will break.
# See: https://github.com/joyent/node/issues/1707
hasOwnProperty = (obj, prop)->
	Object.prototype.hasOwnProperty.call obj, prop

# An instance of class Mundle is created for each client-side request
class Mundle
	constructor:(loadedModules)->
		@loaded = loadedModules
		@queue = 0
 
	# calls readAndParseFile and collects errors and file contents from it and the required file and all dependencies
	require:(file,callback)->
		results = {}
		errors = null
		
		@readAndParseFile file, (err, file, contents)->
			safePath = file.getClientPath()
			results[safePath] = contents
			if err
				(errors or= {})[safePath] = err
				err.path = file.getRelPath()
			if @queue is 0
				callback errors, results

	# recursively read and parse file and dependencies
	readAndParseFile:(file, callback)->
		return if @loaded[file.getClientPath()]
		@queue++
		try
			file.getContents (error, contents)=>
				unless error?
					@loaded[file.getClientPath()] = yes
					@findAndLoadSyncRequires file, contents, callback
				@queue--
				callback.call @, error, file, contents
		catch error
			@queue--
			callback.call @, error, file, ''

	# parses a file for dependencies
	findAndLoadSyncRequires:(file, contents, callback)->
		dependencies = indexCache[file.getClientPath()] or= findRequires contents, raw : yes
		for dependency in dependencies
			if (unprocessedPath = dependency.value)?
				file = new MundleFile relPath : unprocessedPath, parent : file
				@readAndParseFile file, callback

class MundleFile
	constructor:({@clientPath, @relPath, @parent})->
		unless @clientPath? or @relPath?
			console.error "MundleFile needs a path"
			return null
	
	getRelPath:->
		return @relPath or @clientPath

	basePrefix = '/b'
	mundlePrefix = '/m'
	# utility to convert paths in synchronous dependencies to the exact resolution asynchronous dependencies receive on the client-side.
	getClientPath:->
		return @clientPath if @clientPath?
		
		relPath = @getRelPath()
		
		# base paths
		if /^(\.|\.\.)?\//.test relPath
			# "absolute" paths
			if /^\//.test relPath
				return @clientPath = "#{basePrefix}#{relPath}"
			# relative paths
			else
				components = relPath.split '/'
				clientPath = parent @parent.getClientPath()
				while components.length > 0
					switch component = (components.splice 0, 1)[0]
						when '..'
							clientPath = parent clientPath
						when '.'
						else
							clientPath += "/#{component}"
				return @clientPath = clientPath
		# mundle paths
		else
			match = /^(.*?)((@)(.*?))?(\/.*)?$/.exec relPath
			version = match[4] or cache.versions[match[1]] or '0.0.0'
			clientPath = "#{mundlePrefix}/#{match[1]}/#{version}"
			if (subDir = match[5])?
				clientPath += subDir
			return @clientPath = clientPath

	# utility to resolve relative paths from the client and block access below the base path
	getAbsPath:(callback)->
		return callback null, @absPath if @absPath?
		
		gotAbsPath = (absPath, callback)=>
			try
				checkPermission absPath
				callback null, @absPath = absPath
			catch error
				callback error
		
		# base paths
		clientPath = @getClientPath()
		if /^\/b\//.test clientPath
			gotAbsPath (path.join basePath, clientPath[3..]), callback
		# mundle paths
		else if /^\/m\//.test clientPath
			match = /^\/m\/(.*?)\/(.*?)(\/.*)?$/.exec clientPath
			[str, name, version, clientPath] = match
			version = version.replace '0.0.0', 'latest'
			if clientPath?
				# gotAbsPath (path.join mundlesPath, name, version, clientPath), callback
				gotAbsPath (path.join mundlesPath, name, clientPath), callback
			else
				# packagePath = path.join mundlesPath, name, version
				packagePath = path.join mundlesPath, name
				readPackage packagePath, (error, pkg)->
					if error
						callback error
					else
						filename = path.resolve packagePath, pkg.main
						tryFile filename, (error, absPath)->
							unless absPath
								tryFile (path.resolve filename, 'index.js'), (error, absPath)->
									unless absPath
										callback new MundleError message : 'need an error message and test!!!'
									else
										gotAbsPath absPath, callback
							else
								gotAbsPath absPath, callback
		else
			error = new MundleError
				message : 'Incorrectly formed request. Missing request type (/b or /m)'
			callback error

	getContents:(callback)->
		return callback null, @contents if @contents?
		return callback null, @contents if (@contents = fileCache[@getClientPath()])?
		@getAbsPath (error, absPath)=>
			if error?
				callback error
			else
				fs.readFile absPath, 'utf8', (error, contents)=>
					if error?
						{errno, code, syscall} = error
						console.error error, 'at getContents'
						error = new MundleError {
							message : 'Unable to read file'
							errno
							code
							syscall
						}
					callback error, @contents = fileCache[@getClientPath()] =
						processWithPlugins absPath, contents

class MundleError extends Error
	constructor:(options)->
		for own property, value of options
			@[property] = value
		super()

# check if the directory is a package.json dir
readPackage = (requestPath, callback)->
	if (hasOwnProperty(packageCache, requestPath))
		return callback undefined, packageCache[requestPath]
	jsonPath = path.resolve(requestPath, 'package.json')
	fs.readFile jsonPath, 'utf8', (error, json)->
		if error?
			{errno, code, syscall} = error
			console.error error, 'at readPackage'
			return callback new MundleError {
				message : 'Mundle is missing package.json'
				errno
				code
				syscall
			}
		try
			pkg = packageCache[requestPath] = JSON.parse(json)
		catch e
			e.path = jsonPath
			e.message = 'Error parsing ' + jsonPath + ': ' + e.message
			error = new MundleError e
		callback error, pkg

# check if the file exists and is not a directory
tryFile = (requestPath, callback)->
	fs.stat requestPath, (error, stats)->
		if (stats && !stats.isDirectory())
			return fs.realpath requestPath, callback
		callback error, false

checkPermission = (filePath)->
	# check If Below mundlesPath
	return unless /^\.\.\//.test path.relative mundlesPath, filePath
	# check If Below basePath
	return unless /^\.\.\//.test path.relative basePath, filePath
	throw new MundleError
		message : 'Attempt to access a file in an unauthorized location'

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

processWithPlugins = (filePath, contents)->
	extension = (path.extname filePath)[1..]
	if (compiler = loadedPlugins[extension])?
		contents = compiler contents
	contents

getPackageCache = (filePath, clientCacheDiff)->
	filePath = filePath.getClientPath()
	index = filePath + (Object.keys clientCacheDiff).sort()
	return pkgCache[index] or index

addPackageCache = (index, data)->
	pkgCache[index] = cache = new Buffer (JSON.stringify data)
	return cache
	
requestHandler = (req, res, next)->
	if req.url is '/mundlejs/require.js' 
		fs.readFile "#{__dirname}/client.js", (error, clientJs)->
			res.writeHead 200, 'Content-Type' : 'text/javascript'
			res.end clientJs
	else if (req.url.search /^\/mundlejs\//) > -1
		parsedUrl = url.parse req.url[9...], yes
		# if req.headers.clientid?
		# FIXME: We need this? pathname[0] is always / isn't it?
		requestPath = '/' + parsedUrl.pathname[1...]
		file = new MundleFile clientPath : requestPath
		clientCacheDiff = parsedUrl.query
		if (cache = getPackageCache file, clientCacheDiff) instanceof Buffer
			res.writeHead 200, 'Content-Type' : 'text/javascript', 'Content-Length' : cache.length
			res.end cache
		else
			cacheIndex = cache
			serverRequire file, clientCacheDiff, (err, results)->
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
serverRequire = (file, loadedModules, callback)->
	mundle = new Mundle loadedModules
	file = new MundleFile clientPath : file unless file instanceof MundleFile
	mundle.require file, callback

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
