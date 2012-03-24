#@ sourceURL=ModuleTest/Test4.js
Test5 = require 'ModuleTest/Test5.js'

class Test4 extends Test5
  console.log 'Test5 available synchronously', Test5
  
  loadAsyncModule:->
    require 'ModuleTest/Test6.js', (err, Test6)->
      if err then console.warn err
      else
        console.log 'Async load of Test6', Test6

module.exports = Test4