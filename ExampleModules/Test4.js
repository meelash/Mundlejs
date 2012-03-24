(function() {
  var Test4, Test5,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Test5 = require('ExampleModules/Test5.js');

  Test4 = (function(_super) {

    __extends(Test4, _super);

    function Test4() {
      Test4.__super__.constructor.apply(this, arguments);
    }

    console.log('Test5 available synchronously', Test5);

    Test4.prototype.loadAsyncModule = function() {
      return require('ExampleModules/Test6.js', function(err, Test6) {
        if (err) {
          return console.warn(err);
        } else {
          return console.log('Async load of Test6', Test6);
        }
      });
    };

    return Test4;

  })(Test5);

  module.exports = Test4;

}).call(this);
