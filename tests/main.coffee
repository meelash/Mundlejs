serverRequire = require 'mundle'
Browser = require 'zombie'
http = require 'http'
https = require 'https'
fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'

serverTypes =
  HTTPServer : (callback)->
    serverRequire.listen 3000, callback
  # HTTPSServer : (callback)->
  #   serverRequire.listen 3001, key : 1111, callback
  externalHTTPServer : (callback)->
    server = (http.createServer()).listen 3002, callback
    serverRequire.listen server
  # externalHTTPSServer : (callback)->
  #   server = https.createServer key : 1111
  #   server.listen 3003, callback
  #   serverRequire.listen server

createTestFile = (filePath, text)->
  makePath = (dirPath)->
    unless path.existsSync (parent = path.dirname dirPath)
      makePath parent
    fs.mkdirSync dirPath unless path.existsSync dirPath
  
  makePath path.dirname filePath
  fs.writeFileSync filePath, text

exports.testListen = 
  clientServed : (test)->
    serversTested = 0
    test.expect 1 * (Object.keys serverTypes).length
  
    for serverType, serverInit of serverTypes
      do (serverType)->
        server = serverInit ->
          {address, port} = server.address()
          Browser.visit "http://#{address}:#{port}/mundlejs/require.js", (e, browser)->
            test.equal browser.errors.length, 0, "serving client code at #{address}:#{port} over #{serverType}"
            test.done() if ++serversTested is (Object.keys serverTypes).length
            server.close()

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


# 
# 
# exports.testServerRequire =
#   