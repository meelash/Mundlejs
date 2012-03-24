(function() {
  var cache, cacheDiffString, serverRequire,
    __hasProp = Object.prototype.hasOwnProperty;

  window.require = function(path, callback) {
    var exported, source;
    if ((exported = cache.modules[path]) != null) {
      if (typeof callback === "function") callback(null, exported);
      return exported;
    } else if ((source = cache.fetched[path]) != null) {
      return (function() {
        var module;
        module = {
          exports: {}
        };
        console.log("" + path + " eval'ed");
        eval(source);
        exported = cache.modules[path] = module.exports;
        if (typeof callback === "function") callback(null, exported);
        return exported;
      })();
    } else {
      return serverRequire(path, function(err, sources) {
        var source, subPath;
        for (subPath in sources) {
          if (!__hasProp.call(sources, subPath)) continue;
          source = sources[subPath];
          console.log("" + subPath + " fetched");
          cache.fetched[subPath] = source;
          cache.cached[subPath] = true;
        }
        return typeof callback === "function" ? callback(null, require(path)) : void 0;
      });
    }
  };

  serverRequire = function(path, callback) {
    var request;
    request = new XMLHttpRequest();
    request.open('GET', "http://127.0.0.1:1337/" + path + "?" + (cacheDiffString()), true);
    request.setRequestHeader('clientid', 'lakjsdflkjasld');
    request.responseType = 'text';
    request.onload = function() {
      return callback(null, JSON.parse(request.response));
    };
    return request.send();
  };

  cacheDiffString = function() {
    return (Object.keys(cache.cached)).join('=1&' + '=1');
  };

  cache = {
    modules: {},
    fetched: {},
    cached: {}
  };

}).call(this);
