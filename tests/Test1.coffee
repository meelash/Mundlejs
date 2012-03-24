# Test2 will be fetched and evaled immediately
Test2 = require 'Test2.js'

class Test1
  loadAsyncModule:->
    #Test3 will be fetched immediately but not eval'ed until loadAsyncModule is called
    Test3 = require 'Test3.js'
    #Test4 will be fetched (along with its synchronous dependencies) and evaled when loadAsyncModule is called
    require 'Test4.js', (err, Test4)->
      if err then console.warn err
      else
        window.test4 = new Test4

module.exports = Test1