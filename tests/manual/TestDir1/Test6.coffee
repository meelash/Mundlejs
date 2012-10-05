#@ sourceURL=Test6.js
class Test6
  console.log 'Test6 loaded asynchronously', Test6

  testCoffee = require '../TestDir/test.coffee'
  testCoffee()
  
  jade = require '../TestDir/runtime.min.js'
  testTmpl = require '../TestDir/test.jade'
  tmplResult = testTmpl tmplName : 'Jade'
  
  document.getElementsByTagName('body')[0].innerHTML = tmplResult
  
module.exports = Test6