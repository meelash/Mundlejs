serverRequire = require 'mundle'

createTestFile = (filePath, text)->
	makePath = (dirPath)->
		unless fs.existsSync (parent = path.dirname dirPath)
			makePath parent
		fs.mkdirSync dirPath unless fs.existsSync dirPath
	
	makePath path.dirname filePath
	fs.writeFileSync filePath, text

testPlugin = (stubCallback)->
	cacheBundle : (index, bundle, callback)->
		setTimeout ->
			callback null, 'http://locationOfThisBundle.onMyFancyCdn.com/toastyPop'
			stubCallback null, 'http://locationOfThisBundle.onMyFancyCdn.com/toastyPop'
		, 1000

exports.testPlugin =
	testAPI : (test)->
		test.expect 3
		createTestFile "#{__dirname}/testCDN1.js", "require('./testCDN2.js')"
		createTestFile "#{__dirname}/testCDN2.js", "require('./testCDN3.js')"
		createTestFile "#{__dirname}/testCDN3.js", ""
		
		fakeCDN = (index, bundle, callback)->
			test.ok yes, 'CDN plugin should be called from mundle'
			test.equal index, '/b/testCDN1.js/b/testCDN2.js', 'Unique identifier of the package should be passed to the cdn plugin'
			test.equal bundle, 'someStuff', 'Bundle contents should be passed to the cdn plugin'
			test.done()
		serverRequire '/b/testCDN1.js', {'/b/testCDN2.js' : yes}
	
	testMultipleCalls : (test)->
		test.expect 1
		fakeCDN = testPlugin (url)->
			test.equal url, 'http://locationOfThisBundle.onMyFancyCdn.com/toastyPop', 'Callback should only be fired once for multiple calls to the same cached bundle'
			serverRequire '/b/testCDN1.js', {'/b/testCDN2.js' : yes} # even this one, after the plugin has callbacked, shouldn't
			test.done()
			
		serverRequire.use fakeCDN
		serverRequire '/b/testCDN1.js', {'/b/testCDN2.js' : yes}, (errors, results)-> # this one should actually go to the cdn
			serverRequire '/b/testCDN1.js', {'/b/testCDN2.js' : yes} #this one shouldn't
		serverRequire '/b/testCDN1.js', {'/b/testCDN2.js' : yes} #this one, that will go immediately shouldn't either