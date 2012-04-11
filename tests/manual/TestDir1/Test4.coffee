#@ sourceURL=Test4.js
Test5 = require './Test5.js'

class Test4 extends Test5
  
  loadAsyncModule:->
    require './Test6.js', (err, Test6)->
      if err then console.warn err

module.exports = Test4