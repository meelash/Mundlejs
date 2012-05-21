(function() {
  var Module, baseModule, cache, cacheDiffString, requestHostname, requestPort, serverRequire,
    __hasProp = Object.prototype.hasOwnProperty;

  Module = (function() {
    var parent;

    function Module(path) {
      this.path = path;
      this.exports = {};
    }

    Module.prototype.runInContext = function(source) {
      var exports, module, require;
      module = this;
      exports = module.exports;
      require = module.require.bind(module);
      eval(source);
      return module.exports;
    };

    Module.prototype.require = function(path, callback) {
      var exported, source;
      path = this.resolvePath(path);
      if ((exported = cache.modules[path]) != null) {
        if (typeof callback === "function") callback(null, exported);
        return exported;
      } else if ((source = cache.fetched[path]) != null) {
        return (function() {
          var module;
          module = new Module(path);
          exported = cache.modules[path] = module.runInContext(source);
          if (typeof callback === "function") callback(null, exported);
          return exported;
        })();
      } else {
        return serverRequire(path, function(errors, sources) {
          var err, source, subPath, _i, _len;
          if (errors != null) {
            for (_i = 0, _len = errors.length; _i < _len; _i++) {
              err = errors[_i];
              if (err != null) console.warn(err);
            }
          }
          for (subPath in sources) {
            if (!__hasProp.call(sources, subPath)) continue;
            source = sources[subPath];
            cache.fetched[subPath] = source;
            cache.cached[subPath] = true;
          }
          return typeof callback === "function" ? callback(null, require(path)) : void 0;
        });
      }
    };

    Module.prototype.resolvePath = function(path) {
      var component, components;
      if (/^(.|..)\//.test(path)) {
        components = path.split('/');
        path = parent(this.path);
        while (components.length > 0) {
          switch (component = (components.splice(0, 1))[0]) {
            case '..':
              path = parent(path);
              break;
            case '.':
              break;
            default:
              path += "/" + component;
          }
        }
      } else if (/^\//.test(path)) {
        path;
      } else {
        path = "/" + path + ".js";
      }
      return path;
    };

    parent = function(path) {
      var ar;
      ar = path.split('/');
      ar.pop();
      return ar.join('/');
    };

    return Module;

  })();

  baseModule = new Module('');

  window.require = baseModule.require.bind(baseModule);

  requestHostname = window.location.hostname;

  requestPort = window.location.port;

  serverRequire = function(path, callback) {
    var request;
    request = new XMLHttpRequest();
    request.open('GET', "http://" + requestHostname + ":" + requestPort + "/mundlejs" + path + "?" + (cacheDiffString()), true);
    request.setRequestHeader('clientid', 'lakjsdflkjasld');
    request.responseType = 'text';
    request.onload = function() {
      var response;
      response = JSON.parse(request.response);
      return callback(response.err, response.results);
    };
    return request.send();
  };

  cacheDiffString = function() {
    return ((Object.keys(cache.cached)).join('=1&')) + '=1';
  };

  cache = {
    modules: {},
    fetched: {},
    cached: {}
  };

}).call(this);
