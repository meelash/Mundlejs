(function() {
  var Test1, Test2;

  Test2 = require('ModuleTest/Test2.js');

  Test1 = (function() {

    function Test1() {}

    console.log('Test2 available synchronously', Test2);

    Test1.prototype.loadAsyncModule = function() {
      var Test3;
      Test3 = require('ModuleTest/Test3.js');
      console.log('Test3 available synchronously', Test3);
      return require('ModuleTest/Test4.js', function(err, Test4) {
        if (err) {
          return console.warn(err);
        } else {
          window.test4 = new Test4;
          return console.log('Async load of Test4', Test4);
        }
      });
    };

    return Test1;

  })();

  module.exports = Test1;

}).call(this);
