serverRequire = require 'mundle'
phantom = require 'phantom'
http = require 'http'
https = require 'https'
fs = require 'fs'
path = require 'path'
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

# exports.testListen = 
# 	clientServed : (test)->
# 		serversTested = 0
# 		test.expect (Object.keys serverTypes).length
# 		
# 		phantom.create (ph)->
# 			for serverType, serverInit of serverTypes
# 				do (serverType)->
# 					server = serverInit ->
# 						{address, port} = server.address()
# 						ph.createPage (page)->
# 							page.set 'onError', (msg, trace)->
# 								console.log msg
# 								trace.forEach (item)->
# 									console.log "	 #{item.file}:#{item.line}"
# 							page.includeJs "http://#{address}:#{port}/mundlejs/require.js", ->
# 								# test.equal status, 'success', 'serving client code at #{address}:#{port} over #{serverType}'
# 								page.evaluate ->
# 									window.require?
# 								, (exists)->
# 									test.ok exists, 'require function is available'
# 									test.done() if ++serversTested is (Object.keys serverTypes).length
# 									server.close()
# 									ph.exit()
# 			console.warn "Test fails because phantomjs doesn't have function.prototype.bind"
# 			console.warn "http://code.google.com/p/phantomjs/issues/detail?id=522"

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
		request.get 'http://0.0.0.0:3005/mundlejs/b/foo/bar/testConnectFile.js', (res)->
			{results} = (JSON.parse res.text)
			test.deepEqual results, {'/b/foo/bar/testConnectFile.js' : 'Hello, testConnect!!'}, 'Connect respond with the mundle'

			request.get 'http://0.0.0.0:3005/foo/bar/testConnectFile.js', (res)->
				test.deepEqual res.text, 'Mundle didn\'t touch it', 'Connect bypass mundle middleware'
				test.done()