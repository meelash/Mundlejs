(function() {
  var Mundle, basePath, cachePath, cachedPkgs, findRequires, fs, path, resolvePath, sanitizePath, serverRequire, url;

  fs = require('fs');

  path = require('path');

  url = require('url');

  findRequires = require('find-requires');

  cachedPkgs = {};

  basePath = '/';

  Mundle = (function() {

    function Mundle(loadedModules) {
      this.loaded = loadedModules;
      this.queue = 0;
    }

    Mundle.prototype.require = function(path, callback) {
      var errors, results;
      results = {};
      errors = null;
      return this.readAndParseFile(path, basePath, function(err, path, contents) {
        var safePath;
        if ((safePath = sanitizePath(path)).length === 0) {
          results[path] = contents;
        } else {
          results[safePath] = contents;
        }
        if (err) (errors || (errors = [])).push(err);
        if (this.queue === 0) return callback(errors, results);
      });
    };

    Mundle.prototype.readAndParseFile = function(path, parent, callback) {
      var contents;
      try {
        path = resolvePath(path, parent);
      } catch (err) {
        return callback.call(this, err, path, '');
      }
      if (this.loaded[sanitizePath(path)]) return;
      this.queue++;
      try {
        contents = fs.readFileSync(path, 'utf8');
        this.loaded[sanitizePath(path)] = true;
        this.findAndLoadSyncRequires(path, contents, callback);
        this.queue--;
        return callback.call(this, null, path, contents);
      } catch (err) {
        this.queue--;
        return callback.call(this, err, path, '');
      }
    };

    Mundle.prototype.findAndLoadSyncRequires = function(filePath, contents, callback) {
      var dependencies, dependency, syncRequire, _i, _len, _results;
      dependencies = findRequires(contents, {
        raw: true
      });
      _results = [];
      for (_i = 0, _len = dependencies.length; _i < _len; _i++) {
        dependency = dependencies[_i];
        if ((syncRequire = dependency.value) != null) {
          _results.push(this.readAndParseFile(syncRequire, path.dirname(filePath), callback));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    return Mundle;

  })();

  resolvePath = function(relPath, parent) {
    var absPath;
    if (/^(.|..)\//.test(relPath)) {
      if (parent) {
        absPath = path.join(parent, relPath);
      } else {
        absPath = path.join(basePath, relPath);
      }
      if ((sanitizePath(absPath)).length === 0) {
        throw {
          message: 'Unauthorized attempt to access file',
          path: relPath
        };
      } else {
        absPath;
      }
    } else {
      absPath = path.join(basePath, relPath);
      if (!/^\//.test(relPath)) absPath += '.js';
    }
    return absPath;
  };

  sanitizePath = function(path) {
    var re, sanitizedPath;
    sanitizedPath = '';
    re = new RegExp("(^" + basePath + "\/*)(.*)");
    path.replace(re, function(str, p1, p2) {
      return sanitizedPath = "/" + p2;
    });
    return sanitizedPath;
  };

  cachePath = function(path) {};

  serverRequire = function(path, loadedModules, callback) {
    var mundle;
    mundle = new Mundle(loadedModules);
    return mundle.require(path, callback);
  };

  serverRequire.setBasePath = function(relPath) {
    return basePath = path.resolve(relPath);
  };

  serverRequire.setBasePath('./');

  serverRequire.listen = function(server, options, callback) {
    var port;
    if ('function' === typeof options) {
      callback = options;
      options = {};
    }
    if ('undefined' === typeof server) server = 80;
    if ('number' === typeof server) {
      port = server;
      if (options && options.key) {
        server = require('https').createServer(options);
      } else {
        server = require('http').createServer();
      }
      server.on('request', function(req, res) {
        res.writeHead(200);
        return res.end('Welcome to Mundlejs!');
      });
      server.listen(port, callback);
    }
    server.on('request', function(req, res) {
      var clientCacheDiff, clientJs, filePath, parsedUrl;
      if (req.url === '/mundlejs/require.js') {
        clientJs = fs.readFileSync("" + __dirname + "/client.js");
        res.writeHead(200, {
          'Content-Type': 'text/javascript'
        });
        return res.end(clientJs);
      } else if (req.url.search(/^\/mundlejs\// !== -1)) {
        parsedUrl = url.parse(req.url.slice(8), true);
        if (req.headers.clientid != null) {
          filePath = parsedUrl.pathname.slice(1);
          clientCacheDiff = parsedUrl.query;
          return serverRequire(filePath, clientCacheDiff, function(err, results) {
            return res.end(JSON.stringify({
              err: err,
              results: results
            }));
          });
        }
      }
    });
    return server;
  };

  module.exports = serverRequire;

}).call(this);
