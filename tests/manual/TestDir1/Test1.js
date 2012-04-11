(function() {
  var Test1, Test2;

  Test2 = require('./Test2.js');

  Test1 = (function() {

    function Test1() {}

    Test1.prototype.loadAsyncModule = function() {
      var Test3, Test7, testNonLiteral;
      Test3 = require('./Test3.js');
      require('./Test4.js', function(err, Test4) {
        if (err) {
          return console.warn(err);
        } else {
          return window.test4 = new Test4;
        }
      });
      testNonLiteral = './Test7.js';
      Test7 = require(testNonLiteral);
      require('../TestDir/Test8.js', function(err, Test8) {
        return console.log('async Test8', Test8);
      });
      require('../../unauthorizedSync');
      return require('../../unauthorizedAsync', function(err, unauthed) {
        return console.log(arguments);
      });
    };

    return Test1;

  })();

  module.exports = Test1;

}).call(this);
