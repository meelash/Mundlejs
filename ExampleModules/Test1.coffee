# Test2 will be fetched and evaled immediately
Test2 = require 'ExampleModules/Test2.js'

class Test1
  console.log 'Test2 available synchronously', Test2
  
  loadAsyncModule:->
    #Test3 will be fetched immediately but not eval'ed until loadAsyncModule is called
    Test3 = require 'ExampleModules/Test3.js'
    console.log 'Test3 available synchronously', Test3
    #Test4 will be fetched (along with its synchronous dependencies) and evaled when loadAsyncModule is called
    require 'ExampleModules/Test4.js', (err, Test4)->
      if err then console.warn err
      else
        window.test4 = new Test4
        console.log 'Async load of Test4', Test4

module.exports = Test1