# Test2 will be fetched and evaled immediately
Test2 = require './Test2.js'

class Test1
  loadAsyncModule:->
    #Test3 will be fetched immediately but not eval'ed until loadAsyncModule is called
    Test3 = require './Test3.js'
    #Test4 will be fetched (along with its synchronous dependencies) and evaled when loadAsyncModule is called
    require './Test4.js', (err, Test4)->
      if err then console.warn err
      else
        window.test4 = new Test4
    testNonLiteral = './Test7.js'
    Test7 = require testNonLiteral
    require '../TestDir/Test8.js', (err, Test8)->
      console.log 'async Test8', Test8
    require '../../unauthorizedSync'
    require '../../unauthorizedAsync', (err, unauthed)->
      console.log arguments
    require 'MissingModule', (err, MissingModule)->
      console.log 'module by name only', MissingModule
    Test9 = require 'Test9'
    console.log 'module by name only', Test9

module.exports = Test1