serverRequire = require 'mundle'
phantom = require 'phantom'
http = require 'http'
https = require 'https'
fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'

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
                  console.log "  #{item.file}:#{item.line}"
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

# Unify the error reporting and formatting across all kinds of errors.
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
    createTestFile "#{__dirname}/test2.js", "require('../something/Hidden.js')"
    serverRequire 'test2', {}, (errors,results)->
      test.equal errors['../something/Hidden.js'].message, 'Attempt to access file above client-root'
      test.equal errors['../something/Hidden.js'].path, '../something/Hidden.js'
      test.done()

# exports.restrictAccessToRootAndBelow = (test)->
#   serverRequire '../something.js'
#   serverRequire '../hiddenDirectory/something.js'
#   serverRequire '/../something' # FIXME!!! this one fails!
#   etc...

# 
# 
# exports.testServerRequire =
#   


# 
# 
# 
# CLIENT TESTS
# 
# 
#

# exports.testBrowserResponseToErrors

# test keeping the errors with the file for the future attempts at requiring that