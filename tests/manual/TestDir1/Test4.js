(function() {
  var Test4, Test5,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Test5 = require('./Test5.js');

  Test4 = (function(_super) {

    __extends(Test4, _super);

    function Test4() {
      Test4.__super__.constructor.apply(this, arguments);
    }

    Test4.prototype.loadAsyncModule = function() {
      return require('./Test6.coffee', function(err, Test6) {
        if (err) return console.warn(err);
      });
    };

    return Test4;

  })(Test5);

  module.exports = Test4;

}).call(this);
