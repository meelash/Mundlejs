serverRequire = require 'mundle'
phantom = require 'phantom'
http = require 'http'
https = require 'https'
fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'
{loadFile} = require 'mocks'
exposedServerRequire = loadFile "#{__dirname}/node_modules/mundle/lib//exposed/server.js"
connect = require 'connect'
request = require 'superagent'

# 
# 
# 
# SERVER TESTS
# 
# 
#

serverTypes =
	HTTPServer : (callback)->
		serverRequire.listen 3000, callback
	# HTTPSServer : (callback)->
	#		serverRequire.listen 3001, key : 1111, callback
	externalHTTPServer : (callback)->
		server = (http.createServer()).listen 3002, callback
		serverRequire.listen server
	# externalHTTPSServer : (callback)->
	#		server = https.createServer key : 1111
	#		server.listen 3003, callback
	#		serverRequire.listen server
	connectServer : (callback)->
		app = connect()
		(app.use serverRequire.connect())
			.listen 3004, callback

createTestFile = (filePath, text)->
	makePath = (dirPath)->
		unless fs.existsSync (parent = path.dirname dirPath)
			makePath parent
		fs.mkdirSync dirPath unless fs.existsSync dirPath
	
	makePath path.dirname filePath
	fs.writeFileSync filePath, text

exports.testListen = 
	clientServed : (test)->
		serversTested = 0
		test.expect (Object.keys serverTypes).length
		
		phantom.create (ph)->
			for serverType, serverInit of serverTypes
				do (serverType)->
					server = serverInit ->
						{address, port} = server.address()
						ph.createPage (page)->
							page.set 'onError', (msg, trace)->
								console.log msg
								trace.forEach (item)->
									console.log "	 #{item.file}:#{item.line}"
							page.includeJs "http://#{address}:#{port}/mundlejs/require.js", ->
								# test.equal status, 'success', 'serving client code at #{address}:#{port} over #{serverType}'
								page.evaluate ->
									window.require?
								, (exists)->
									test.ok exists, 'require function is available'
									test.done() if ++serversTested is (Object.keys serverTypes).length
									server.close()
									ph.exit()
			console.warn "Test fails because phantomjs doesn't have function.prototype.bind"
			console.warn "http://code.google.com/p/phantomjs/issues/detail?id=522"

exports.testConnect = (test)->
	test.expect 3
	app = connect()
		.use(serverRequire.connect())
		.use (req, res)->
			test.ok 'One test gets through past the mundle middleware'
			res.writeHead 200, 'Content-Type' : 'text/javascript'
			res.end 'Mundle didn\'t touch it'
	.listen 3005, ->
		relTestPath = path.relative process.cwd(), "#{__dirname}/foo/bar/testConnectFile.js"
		createTestFile relTestPath, 'Hello, testConnect!!'
		request.get 'http://0.0.0.0:3005/mundlejs/tmp/mundleTest/foo/bar/testConnectFile.js', (res)->
			{results} = (JSON.parse res.text)
			test.deepEqual results, {'/tmp/mundleTest/foo/bar/testConnectFile.js' : 'Hello, testConnect!!'}, 'Connect respond with the mundle'
		
			request.get 'http://0.0.0.0:3005/tmp/mundleTest/foo/bar/testConnectFile.js', (res)->
				test.deepEqual res.text, 'Mundle didn\'t touch it', 'Connect bypass mundle middleware'
				test.done()

exports.testSetBasePath =
	relativePath : (test)->
		relTestPath = path.relative process.cwd(), "#{__dirname}/foo/bar/testFile.js"
		createTestFile relTestPath, 'Hello, mundlejs!!'
	
		test.expect 2
		serverRequire.setBasePath path.dirname relTestPath
		serverRequire '/testFile.js', {}, (errors, results)->
			test.ifError errors
			test.deepEqual results, {'/testFile.js' : 'Hello, mundlejs!!'}
			test.done()
			
	absolutePath : (test)->
		absTestPath = "#{__dirname}/foo1/bar1/testFile.js"
		createTestFile absTestPath, 'Hello, mundlejs!!'
	
		test.expect 2
		serverRequire.setBasePath path.dirname absTestPath
		serverRequire '/testFile.js', {}, (errors, results)->
			test.ifError errors
			test.deepEqual results, {'/testFile.js' : 'Hello, mundlejs!!'}, errors
			test.done()

# 'nested' refers to parsed synchronous require calls in a file vs. a top level error in an asynchronous require
exports.testErrorFormatting =
	setUp : (callback)->
		serverRequire.setBasePath __dirname
		callback()
		
	noErrors : (test)->
		test.expect 1
		createTestFile "#{__dirname}/test2.js", ""
		serverRequire 'test2', {}, (errors,results)->
			test.ifError errors
			test.done()
		
	fileNotFoundError : (test)->
		test.expect 2
		serverRequire '/doesnt/exist.js', {}, (errors,results)->
			test.equal errors['/doesnt/exist.js'].message, 'No such file or directory'
			test.equal errors['/doesnt/exist.js'].path, '/doesnt/exist.js'
			test.done()
	
	nestedFileNotFoundError : (test)->
		test.expect 2
		createTestFile "#{__dirname}/test1.js", "require('/doesnt/exist.js')"
		serverRequire 'test1', {}, (errors,results)->
			test.equal errors['/doesnt/exist.js'].message, 'No such file or directory'
			test.equal errors['/doesnt/exist.js'].path, '/doesnt/exist.js'
			test.done()
	
	accessAboveRoot1 : (test)->
		test.expect 2
		serverRequire '../something/Hidden.js', {}, (errors,results)->
			test.equal errors['../something/Hidden.js'].message, 'Attempt to access file above client-root'
			test.equal errors['../something/Hidden.js'].path, '../something/Hidden.js'
			test.done()
	
	accessAboveRoot2 : (test)->
		test.expect 2
		serverRequire '/../something/Hidden.js', {}, (errors,results)->
			test.equal errors['/../something/Hidden.js'].message, 'Attempt to access file above client-root'
			test.equal errors['/../something/Hidden.js'].path, '/../something/Hidden.js'
			test.done()
	
	nestedAccessAboveRoot : (test)->
		test.expect 2
		createTestFile "#{__dirname}/testNestedAccessAboveRoot.js", "require('../something/Hidden1.js')"
		serverRequire 'testNestedAccessAboveRoot', {}, (errors,results)->
			test.equal errors['../something/Hidden1.js'].message, 'Attempt to access file above client-root'
			test.equal errors['../something/Hidden1.js'].path, '../something/Hidden1.js'
			test.done()

exports.testCache =
	setUp : (callback)->
		exposedServerRequire.module.exports.setBasePath __dirname
		callback()
		
	dependencies:(test)->
		test.expect 4
		createTestFile "#{__dirname}/testCache1.js", "require('./testCache2.js')"
		createTestFile "#{__dirname}/testCache2.js", "require('./testCache3.js')"
		createTestFile "#{__dirname}/testCache3.js", ""
		exposedServerRequire.module.exports "testCache1", {}, (errors, results)->
			test.deepEqual exposedServerRequire.indexCache?["/testCache1.js"], [
				value : './testCache2.js'
				raw : '\'./testCache2.js\''
				point : 9
				line : 1,
				column : 9
			], "dependencies should have been added to the cache"
			test.deepEqual exposedServerRequire.indexCache?["/testCache2.js"], [
				value : './testCache3.js'
				raw : '\'./testCache3.js\''
				point : 9
				line : 1,
				column : 9
			], "dependencies should have been added to the cache"
			exposedServerRequire.fileCache["/testCache2.js"] = "require('./testCache4.js')"
			exposedServerRequire.module.exports 'testCache1', {}, (errors, results)->
				test.ok results['/testCache3.js']?, 'dependencies should have been loaded based on the cache, not the modified file'
				exposedServerRequire.module.exports 'testCache1', {'/testCache3.js' : yes}, (errors, results)->
					test.deepEqual results, 
						'/testCache1.js' : "require('./testCache2.js')"
						'/testCache2.js' : "require('./testCache4.js')"
					, 'The bundles already on the client should be taken into account when building a bundle from the cached dependencies'
					test.done()

	files:(test)->
		test.expect 3
		createTestFile "#{__dirname}/testCacheFiles1.js", "require('./testCacheFiles2.js')"
		createTestFile "#{__dirname}/testCacheFiles2.js", "require('./testCacheFiles3.js')"
		createTestFile "#{__dirname}/testCacheFiles3.js", ""
		exposedServerRequire.module.exports "testCacheFiles1", {}, (errors, results)->
			test.deepEqual exposedServerRequire.fileCache?["/testCacheFiles1.js"], "require('./testCacheFiles2.js')", "contents of testCacheFiles1 should have been added to the cache"
			test.deepEqual exposedServerRequire.fileCache?["/testCacheFiles2.js"], "require('./testCacheFiles3.js')", "contents of testCacheFiles2 should have been added to the cache"
			createTestFile "#{__dirname}/testCacheFiles2.js", "require('./testCacheFiles3.js'); 'asdasdfasdf'"
			exposedServerRequire.module.exports 'testCacheFiles1', {}, (errors, results)->
				test.deepEqual results, 
					'/testCacheFiles1.js' : "require('./testCacheFiles2.js')"
					'/testCacheFiles2.js' : "require('./testCacheFiles3.js')"
					'/testCacheFiles3.js' : ""
				, 'file should have been loaded from the cache, not the modified file'
				test.done()

testPlugin =
	extensions: ['testPlugin0', 'testPlugin01']
	compiler: (text)->
		'The testPlugin compiler worked!'

testPlugin1 =
	extensions: ['testPlugin1', 'testPlugin11']
	compiler: (text)->
		'The testPlugin1 compiler worked!'

testPlugin2 =
	extensions: ['testPlugin2', 'testPlugin21']
	compiler: (text)->
		'The testPlugin2 compiler worked!'

exports.testPlugin =
	singlePlugin:(test)->
		test.expect 4
		createTestFile "#{__dirname}/testPlugin.testPlugin0", "blabkabjakjblaklajbljabl"
		createTestFile "#{__dirname}/testPlugin.testPlugin01", "blabkabjakjblaklajbljabl"
		serverRequire.use testPlugin
		serverRequire '/testPlugin.testPlugin0', {}, (errors, modules)->
			test.ifError errors, 'No errors should be returned'
			test.deepEqual modules, {'/testPlugin.testPlugin0':'The testPlugin compiler worked!'}, 'Compiler should have returned compiled code from plugin 0'
			serverRequire '/testPlugin.testPlugin01', {}, (errors, modules)->
				test.ifError errors, 'No errors should be returned'
				test.deepEqual modules, {'/testPlugin.testPlugin01':'The testPlugin compiler worked!'}, 'Compiler should have returned compiled code from plugin 1'
				test.done()
	multiplePlugin:(test)->
		test.expect 8
		createTestFile "#{__dirname}/testPlugin.testPlugin1", "blabkabjakjblaklajbljabl"
		createTestFile "#{__dirname}/testPlugin.testPlugin11", "blabkabjakjblaklajbljabl"
		serverRequire.use [testPlugin1, testPlugin2]
		serverRequire '/testPlugin.testPlugin1', {}, (errors, modules)->
			test.ifError errors, 'No errors should be returned'
			test.deepEqual modules, {'/testPlugin.testPlugin1':'The testPlugin1 compiler worked!'}, 'Compiler should have returned compiled code from plugin 0 using first compiler'
			serverRequire '/testPlugin.testPlugin11', {}, (errors, modules)->
				test.ifError errors, 'No errors should be returned'
				test.deepEqual modules, {'/testPlugin.testPlugin11':'The testPlugin1 compiler worked!'}, 'Compiler should have returned compiled code from plugin 1 using first compiler'


				createTestFile "#{__dirname}/testPlugin.testPlugin2", "blabkabjakjblaklajbljabl"
				createTestFile "#{__dirname}/testPlugin.testPlugin21", "blabkabjakjblaklajbljabl"
				serverRequire '/testPlugin.testPlugin2', {}, (errors, modules)->
					test.ifError errors, 'No errors should be returned'
					test.deepEqual modules, {'/testPlugin.testPlugin2':'The testPlugin2 compiler worked!'}, 'Compiler should have returned compiled code from plugin 0 using second compiler'
					serverRequire '/testPlugin.testPlugin21', {}, (errors, modules)->
						test.ifError errors, 'No errors should be returned'
						test.deepEqual modules, {'/testPlugin.testPlugin21':'The testPlugin2 compiler worked!'}, 'Compiler should have returned compiled code from plugin 1 using second compiler'
						test.done()
		



# 
# 
# 
# CLIENT TESTS
# 
# 
#

# exports.testBrowserResponseToErrors

# test keeping the errors with the file for the future attempts at requiring that