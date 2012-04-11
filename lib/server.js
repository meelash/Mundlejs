(function() {
  var Mundle, basePath, cachePath, cachedPkgs, findRequires, fs, path, resolvePath, sanitizePath, serverRequire;

  fs = require('fs');

  path = require('path');

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
      if (this.loaded[path]) return;
      this.queue++;
      try {
        contents = fs.readFileSync(path, 'utf8');
        this.loaded[path] = true;
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
        throw 'Unauthorized attempt to access file';
      } else {
        return absPath;
      }
    } else {
      return absPath = path.join(basePath, relPath);
    }
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

  module.exports = serverRequire;

}).call(this);
