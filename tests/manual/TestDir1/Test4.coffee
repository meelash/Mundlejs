#@ sourceURL=Test4.js
Test5 = require './Test5.js'

class Test4 extends Test5
  
  loadAsyncModule:->
    require './Test6.coffee', (err, Test6)->
      if err then console.warn err

module.exports = Test4