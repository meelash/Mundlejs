serverRequire = require 'mundle'
fs = require 'fs'
path = require 'path'
{loadFile} = require 'mocks'
exposedServerRequire = loadFile "#{__dirname}/node_modules/mundle/lib//exposed/server.js"

# 
# 
# 
# SERVER TESTS
# 
# 
#

createTestFile = (filePath, text)->
	makePath = (dirPath)->
		unless fs.existsSync (parent = path.dirname dirPath)
			makePath parent
		fs.mkdirSync dirPath unless fs.existsSync dirPath
	
	makePath path.dirname filePath
	fs.writeFileSync filePath, text


exports.testSetBasePath =
	relativePath : (test)->
		relTestPath = path.relative process.cwd(), "#{__dirname}/foo/bar/testFile.js"
		createTestFile relTestPath, 'Hello, mundlejs!!'

		test.expect 2
		serverRequire.setBasePath path.dirname relTestPath
		serverRequire '/b/testFile.js', {}, (errors, results)->
			test.ifError errors
			test.deepEqual results, {'/b/testFile.js' : 'Hello, mundlejs!!'}
			test.done()

	absolutePath : (test)->
		absTestPath = "#{__dirname}/foo1/bar1/testFile1.js"
		createTestFile absTestPath, 'Hello, mundlejs!!'

		test.expect 2
		serverRequire.setBasePath path.dirname absTestPath
		serverRequire '/b/testFile1.js', {}, (errors, results)->
			test.ifError errors
			test.deepEqual results, {'/b/testFile1.js' : 'Hello, mundlejs!!'}, errors
			test.done()

exports.testDependencyResolution = {}

### 
	The Mundle in "testMundle" actually refers to the packages installed by mundle install.
	Currently we're not supporting versioning. But some of the client-side work for it was done already, so the tests exercise those cases.
###
# 'nested' refers to parsed synchronous require calls in a file vs. top level, i.e. an asynchronous require
exports.testMundle =
	standardPackage : (test)->
		test.expect 2
		contents = fs.readFileSync "#{__dirname}/mundles/testMundle1/underscore.js", 'utf8'
		serverRequire '/m/testMundle1/1.4.2', {}, (errors, results)->
			test.ifError errors
			test.equal results['/m/testMundle1/1.4.2'], contents, 'Should get file contents of main js file'
			test.done()
	
	standardPackageDefaultVersion : (test)->
		test.expect 2
		contents = fs.readFileSync "#{__dirname}/mundles/testMundle1/underscore.js", 'utf8'
		serverRequire '/m/testMundle1/0.0.0', {}, (errors, results)->
			test.ifError errors
			test.equal results['/m/testMundle1/0.0.0'], contents, 'Should get file contents of main js file'
			test.done()
	
	standardPackageSubFile : (test)->
		test.expect 2
		contents = fs.readFileSync "#{__dirname}/mundles/testMundle1/underscore-min.js", 'utf8'
		serverRequire '/m/testMundle1/1.4.2/underscore-min.js', {}, (errors, results)->
			test.ifError errors
			test.equal results['/m/testMundle1/1.4.2/underscore-min.js'], contents, 'Should get file contents of main js file'
			test.done()
	
	standardPackageDefaultVersionSubFile : (test)->
		test.expect 2
		contents = fs.readFileSync "#{__dirname}/mundles/testMundle1/underscore-min.js", 'utf8'
		serverRequire '/m/testMundle1/0.0.0/underscore-min.js', {}, (errors, results)->
			test.ifError errors
			test.equal results['/m/testMundle1/0.0.0/underscore-min.js'], contents, 'Should get file contents of main js file'
			test.done()
	
	mundleNestedDependencyPathResolution : (test)->
		test.expect 6
		serverRequire '/m/testMundleNestedDependencies/0.0.0', {}, (errors, results)->
			test.ok ((Object.keys results).indexOf '/m/testMundleNestedDependencies/0.0.0/foo.js') isnt -1, 'Relative path as a mundle nested dependency'
			test.ok ((Object.keys results).indexOf '/b/bar/foo.js') isnt -1, 'Absolute path as a mundle nested dependency'
			test.ok ((Object.keys results).indexOf '/m/foo/0.0.0') isnt -1, 'Mundle as a mundle nested dependency'
			test.ok ((Object.keys results).indexOf '/m/foo/1.1.1') isnt -1, 'Mundle with version as a mundle nested dependency'
			test.ok ((Object.keys results).indexOf '/m/foo/0.0.0/bar.js') isnt -1, 'Mundle and a relative path as a mundle nested dependency'
			test.ok ((Object.keys results).indexOf '/m/foo/1.1.1/bar.js') isnt -1, 'Mundle with version and a relative path as a mundle nested dependency'
			test.done()
	
	noPackageJson : (test)->
		test.expect 1
		serverRequire '/m/testMundleNoPackageJson/0.0.0', {}, (errors, results)->
			test.equal results['/m/testMundleNoPackageJson/0.0.0'], 'testMundleNoPackageJson works!!', 'Contents should be loaded from index.js'
			test.done()
	
	noMainInPackageJson : (test)->
		test.expect 1
		serverRequire '/m/testMundleNoMainInPackageJson/0.0.0', {}, (errors, results)->
			test.equal results['/m/testMundleNoMainInPackageJson/0.0.0'], 'testMundleNoMainInPackageJson works!!', 'Contents should be loaded from index.js'
			test.done()

# 'nested' refers to parsed synchronous require calls in a file vs. a top level error in an asynchronous require
exports.testErrorFormatting =
	setUp : (callback)->
		serverRequire.setBasePath __dirname
		callback()

	noErrors : (test)->
		test.expect 1
		createTestFile "#{__dirname}/test2.js", ""
		serverRequire '/b/test2.js', {}, (errors,results)->
			test.ifError errors
			test.done()

	fileNotFoundError : (test)->
		test.expect 2
		serverRequire '/b/doesnt/exist.js', {}, (errors,results)->
			test.equal errors['/b/doesnt/exist.js'].message, 'Unable to read file', 'Check error message'
			test.equal errors['/b/doesnt/exist.js'].path, '/b/doesnt/exist.js', 'Check error path'
			test.done()

	nestedFileNotFoundError : (test)->
		test.expect 2
		createTestFile "#{__dirname}/test1.js", "require('/doesnt/exist.js')"
		serverRequire '/b/test1.js', {}, (errors,results)->
			test.equal errors['/b/doesnt/exist.js'].message, 'Unable to read file'
			test.equal errors['/b/doesnt/exist.js'].path, '/doesnt/exist.js'
			test.done()

	unprocessedByClient : (test)->
		test.expect 2
		serverRequire '../something/Hidden.js', {}, (errors,results)->
			test.equal errors['../something/Hidden.js'].message, 'Incorrectly formed request. Missing request type (/b or /m)'
			test.equal errors['../something/Hidden.js'].path, '../something/Hidden.js'
			test.done()

	accessAboveRoot : (test)->
		test.expect 2
		serverRequire '/b/../something/Hidden.js', {}, (errors,results)->
			test.equal errors['/b/../something/Hidden.js'].message, 'Attempt to access a file in an unauthorized location'
			test.equal errors['/b/../something/Hidden.js'].path, '/b/../something/Hidden.js'
			test.done()

	nestedAccessAboveRoot : (test)->
		test.expect 2
		createTestFile "#{__dirname}/testNestedAccessAboveRoot.js", "require('../something/Hidden1.js')"
		serverRequire '/b/testNestedAccessAboveRoot.js', {}, (errors,results)->
			test.equal errors['/b/something/Hidden1.js'].message, 'Unable to read file'
			test.equal errors['/b/something/Hidden1.js'].path, '../something/Hidden1.js'
			test.done()
	
	mundleCouldntResolveFile : (test)->
		test.expect 2
		serverRequire '/m/testErrorFormattingMundleCouldntResolveFile/0.0.0', {}, (errors, results)->
			test.equal errors['/m/testErrorFormattingMundleCouldntResolveFile/0.0.0'].message, 'Unable to read file', 'Check error message'
			test.equal errors['/m/testErrorFormattingMundleCouldntResolveFile/0.0.0'].path, '/m/testErrorFormattingMundleCouldntResolveFile/0.0.0', 'Check error path'
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
		exposedServerRequire.module.exports "/b/testCache1.js", {}, (errors, results)->
			test.deepEqual exposedServerRequire.indexCache?["/b/testCache1.js"], [
				value : './testCache2.js'
				raw : '\'./testCache2.js\''
				point : 9
				line : 1,
				column : 9
			], "dependencies should have been added to the cache"
			test.deepEqual exposedServerRequire.indexCache?["/b/testCache2.js"], [
				value : './testCache3.js'
				raw : '\'./testCache3.js\''
				point : 9
				line : 1,
				column : 9
			], "dependencies should have been added to the cache"
			exposedServerRequire.fileCache["/b/testCache2.js"] = "require('./testCache4.js')"
			exposedServerRequire.module.exports '/b/testCache1.js', {}, (errors, results)->
				test.ok results['/b/testCache3.js']?, 'dependencies should have been loaded based on the cache, not the modified file'
				exposedServerRequire.module.exports '/b/testCache1.js', {'/b/testCache3.js' : yes}, (errors, results)->
					test.deepEqual results, 
						'/b/testCache1.js' : "require('./testCache2.js')"
						'/b/testCache2.js' : "require('./testCache4.js')"
					, 'The bundles already on the client should be taken into account when building a bundle from the cached dependencies'
					test.done()

	files:(test)->
		test.expect 3
		createTestFile "#{__dirname}/testCacheFiles1.js", "require('./testCacheFiles2.js')"
		createTestFile "#{__dirname}/testCacheFiles2.js", "require('./testCacheFiles3.js')"
		createTestFile "#{__dirname}/testCacheFiles3.js", ""
		exposedServerRequire.module.exports "/b/testCacheFiles1.js", {}, (errors, results)->
			test.deepEqual exposedServerRequire.fileCache?["/b/testCacheFiles1.js"], "require('./testCacheFiles2.js')", "contents of testCacheFiles1 should have been added to the cache"
			test.deepEqual exposedServerRequire.fileCache?["/b/testCacheFiles2.js"], "require('./testCacheFiles3.js')", "contents of testCacheFiles2 should have been added to the cache"
			createTestFile "#{__dirname}/testCacheFiles2.js", "require('./testCacheFiles3.js'); 'asdasdfasdf'"
			exposedServerRequire.module.exports '/b/testCacheFiles1.js', {}, (errors, results)->
				test.deepEqual results, 
					'/b/testCacheFiles1.js' : "require('./testCacheFiles2.js')"
					'/b/testCacheFiles2.js' : "require('./testCacheFiles3.js')"
					'/b/testCacheFiles3.js' : ""
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
		serverRequire '/b/testPlugin.testPlugin0', {}, (errors, modules)->
			test.ifError errors, 'No errors should be returned'
			test.deepEqual modules, {'/b/testPlugin.testPlugin0':'The testPlugin compiler worked!'}, 'Compiler should have returned compiled code from plugin 0'
			serverRequire '/b/testPlugin.testPlugin01', {}, (errors, modules)->
				test.ifError errors, 'No errors should be returned'
				test.deepEqual modules, {'/b/testPlugin.testPlugin01':'The testPlugin compiler worked!'}, 'Compiler should have returned compiled code from plugin 1'
				test.done()

	multiplePlugin:(test)->
		test.expect 8
		createTestFile "#{__dirname}/testPlugin.testPlugin1", "blabkabjakjblaklajbljabl"
		createTestFile "#{__dirname}/testPlugin.testPlugin11", "blabkabjakjblaklajbljabl"
		serverRequire.use [testPlugin1, testPlugin2]
		serverRequire '/b/testPlugin.testPlugin1', {}, (errors, modules)->
			test.ifError errors, 'No errors should be returned'
			test.deepEqual modules, {'/b/testPlugin.testPlugin1':'The testPlugin1 compiler worked!'}, 'Compiler should have returned compiled code from plugin 0 using first compiler'
			serverRequire '/b/testPlugin.testPlugin11', {}, (errors, modules)->
				test.ifError errors, 'No errors should be returned'
				test.deepEqual modules, {'/b/testPlugin.testPlugin11':'The testPlugin1 compiler worked!'}, 'Compiler should have returned compiled code from plugin 1 using first compiler'


				createTestFile "#{__dirname}/testPlugin.testPlugin2", "blabkabjakjblaklajbljabl"
				createTestFile "#{__dirname}/testPlugin.testPlugin21", "blabkabjakjblaklajbljabl"
				serverRequire '/b/testPlugin.testPlugin2', {}, (errors, modules)->
					test.ifError errors, 'No errors should be returned'
					test.deepEqual modules, {'/b/testPlugin.testPlugin2':'The testPlugin2 compiler worked!'}, 'Compiler should have returned compiled code from plugin 0 using second compiler'
					serverRequire '/b/testPlugin.testPlugin21', {}, (errors, modules)->
						test.ifError errors, 'No errors should be returned'
						test.deepEqual modules, {'/b/testPlugin.testPlugin21':'The testPlugin2 compiler worked!'}, 'Compiler should have returned compiled code from plugin 1 using second compiler'
						test.done()