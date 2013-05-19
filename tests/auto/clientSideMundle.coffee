#
# 
# 
# CLIENT TESTS
# 
# 
#

global.window = window = {
	location :
		hostname : 'test'
		port : '1111'
}
tieRequestToTest = (callback)->
	window.XMLHttpRequest = global.XMLHttpRequest = ->
		requestInstance =
			open : (verb, request)->
				setTimeout ->
					callback request, requestInstance
				, 0
			send : ->

require 'mundle/lib/client.js'

### 
	Currently we're not supporting versioning. But some of the client-side work for it was done already, so the tests exercise those cases.
###
exports.testResolvePath =
	relative : (test)->
		test.expect 1
		tieRequestToTest (request)->
			test.equal request, '//test:1111/mundlejs/b/foo.js?=1', 'proper request should be formed'
			test.done()
		window.require './bar/../foo.js'
	
	absolute : (test)->
		test.expect 1
		tieRequestToTest (request)->
			test.equal request, '//test:1111/mundlejs/b/bar/foo.js?=1', 'proper request should be formed'
			test.done()
		window.require '/bar/foo.js'
		
	subFileRelative : (test)->
		test.expect 2
		tieRequestToTest (request, requestFn)->
			test.equal request, '//test:1111/mundlejs/b/bar/foo1.js?=1', 'proper request should be formed'
			requestFn.response = JSON.stringify 
				err: null
				results:
					'/b/bar/foo1.js' :
						"""
							module.exports = window.testSubFileRelative = function(path) {
							  return require(path);
							};
						"""
			requestFn.onload()
		window.require '/bar/foo1.js', ->
			tieRequestToTest (request)->
				test.equal request, '//test:1111/mundlejs/b/bar/foo2.js?/b/bar/foo1.js=1', 'proper request should be formed'
				test.done()
			window.testSubFileRelative './foo2.js'
	
	subFileAbsolute : (test)->
		test.expect 1
		tieRequestToTest (request, requestFn)->
			test.equal request, '//test:1111/mundlejs/b/bar/foo1.js?=1', 'request should not fire because cached'
			requestFn.response = '{}'
			requestFn.onload()
		window.require '/bar/foo1.js', ->
			tieRequestToTest (request)->
				test.equal request, '//test:1111/mundlejs/b/foo2.js?/b/bar/foo1.js=1', 'proper request should be formed'
				test.done()
			window.testSubFileRelative '/foo2.js'
	
	mundle : (test)->
		test.expect 1
		tieRequestToTest (request)->
			test.equal request, '//test:1111/mundlejs/m/foo/0.0.0?/b/bar/foo1.js=1', 'proper request should be formed'
			test.done()
		window.require 'foo'
		
	mundleWithVersion : (test)->
		test.expect 1
		tieRequestToTest (request)->
			test.equal request, '//test:1111/mundlejs/m/foo/1.1.1?/b/bar/foo1.js=1', 'proper request should be formed'
			test.done()
		window.require 'foo@1.1.1'
	
	mundlePreviouslyLoadedWithVersion : (test)->
		test.expect 2
		tieRequestToTest (request, requestFn)->
			test.equal request, '//test:1111/mundlejs/m/foo1/1.1.2?/b/bar/foo1.js=1', 'proper request should be formed'
			requestFn.response = JSON.stringify 
				err: null
				results:
					'/m/foo1/1.1.2' : "module.exports = 'foo1@1.1.2 contents'"
			requestFn.onload()
		window.require 'foo1@1.1.2', ->
			window.require 'foo1', (err, result)->
				test.equal result, 'foo1@1.1.2 contents', 'previously loaded version should be returned'
				test.done()
	
	mundlePreviouslyLoadedDifferentVersion : (test)->
		test.expect 1
		tieRequestToTest (request)->
			test.equal request, '//test:1111/mundlejs/m/foo1/1.1.3?/b/bar/foo1.js=1&/m/foo1/1.1.2=1', 'proper request should be formed'
			test.done()
		window.require 'foo1@1.1.3'
		
	mundlePreviouslyLoaded : (test)->
		test.expect 2
		tieRequestToTest (request, requestFn)->
			test.equal request, '//test:1111/mundlejs/m/foo2/0.0.0?/b/bar/foo1.js=1&/m/foo1/1.1.2=1', 'proper request should be formed'
			requestFn.response = JSON.stringify 
				err: null
				results:
					'/m/foo2/1.1.4' : "module.exports = 'foo2@1.1.4 contents'"
			requestFn.onload()
		window.require 'foo2', ->
			window.require 'foo2@1.1.4', (err, result)->
				test.equal result, 'foo2@1.1.4 contents'
				test.done()
	
	mundleWithRel : (test)->
		test.expect 1
		tieRequestToTest (request)->
			test.equal request, '//test:1111/mundlejs/m/foo/0.0.0/bar.js?/b/bar/foo1.js=1&/m/foo1/1.1.2=1&/m/foo2/1.1.4=1', 'proper request should be formed'
			test.done()
		window.require 'foo/bar.js'
		
	mundleWithVersionAndRel : (test)->
		test.expect 1
		tieRequestToTest (request)->
			test.equal request, '//test:1111/mundlejs/m/foo/1.1.1/bar.js?/b/bar/foo1.js=1&/m/foo1/1.1.2=1&/m/foo2/1.1.4=1', 'proper request should be formed'
			test.done()
		window.require 'foo@1.1.1/bar.js'
	
	mundlePreviouslyLoadedWithRel : (test)->
		test.expect 2
		tieRequestToTest (request, requestFn)->
			test.equal request, '//test:1111/mundlejs/m/foo3/0.0.0?/b/bar/foo1.js=1&/m/foo1/1.1.2=1&/m/foo2/1.1.4=1', 'proper request should be formed'
			requestFn.response = JSON.stringify 
				err: null
				results:
					'/m/foo3/1.1.1' :
						"""
							window.testSubFile = function(path) {
							  return require(path);
							};
						"""
			requestFn.onload()
		window.require 'foo3', ->
			tieRequestToTest (request)->
				test.equal request, '//test:1111/mundlejs/m/foo3/1.1.1/bar.js?/b/bar/foo1.js=1&/m/foo1/1.1.2=1&/m/foo2/1.1.4=1&/m/foo3/1.1.1=1', 'proper request should be formed'
				test.done()
			window.require 'foo3/bar.js'
	
	subMundleRelative : (test)->
		test.expect 1
		window.require 'foo3', ->
			tieRequestToTest (request)->
				test.equal request, '//test:1111/mundlejs/m/foo3/1.1.1/baz.js?/b/bar/foo1.js=1&/m/foo1/1.1.2=1&/m/foo2/1.1.4=1&/m/foo3/1.1.1=1', 'proper request should be formed'
				test.done()
			window.testSubFile './baz.js'
	
	subMundleAbsolute : (test)->
		test.expect 1
		window.require 'foo3', ->
			tieRequestToTest (request)->
				test.equal request, '//test:1111/mundlejs/b/baz.js?/b/bar/foo1.js=1&/m/foo1/1.1.2=1&/m/foo2/1.1.4=1&/m/foo3/1.1.1=1', 'proper request should be formed'
				test.done()
			window.testSubFile '/baz.js'
	
	subMundleMundle : (test)->
		test.expect 1
		window.require 'foo3', ->
			tieRequestToTest (request)->
				test.equal request, '//test:1111/mundlejs/m/baz/0.0.0?/b/bar/foo1.js=1&/m/foo1/1.1.2=1&/m/foo2/1.1.4=1&/m/foo3/1.1.1=1', 'proper request should be formed'
				test.done()
			window.testSubFile 'baz'

# exports.testBrowserResponseToErrors

# test keeping the errors with the file for the future attempts at requiring that