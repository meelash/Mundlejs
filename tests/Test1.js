(function() {
  var Test1, Test2;
  Test2 = require('Test2.js');
  Test1 = (function() {
    function Test1() {}
    Test1.prototype.loadAsyncModule = function() {
      var Test3;
      Test3 = require('Test3.js');
      return require('Test4.js', function(err, Test4) {
        if (err) {
          return console.warn(err);
        } else {
          return window.test4 = new Test4;
        }
      });
    };
    return Test1;
  })();
  module.exports = Test1;
}).call(this);
