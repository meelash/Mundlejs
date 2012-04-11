(function() {
  var basePath, cachePath, cachedPkgs, findAndLoadSyncRequires, findRequires, fs, loaded, path, queue, readAndParseFile, resolvePath, sanitizePath, serverRequire;

  fs = require('fs');

  path = require('path');

  findRequires = require('find-requires');

  cachedPkgs = {};

  loaded = {};

  queue = 0;

  basePath = '/';

  serverRequire = function(path, loadedModules, callback) {
    var errors, results;
    loaded = loadedModules;
    queue = 0;
    results = {};
    errors = null;
    return readAndParseFile(path, basePath, function(err, path, contents) {
      var safePath;
      if ((safePath = sanitizePath(path)).length === 0) {
        results[path] = contents;
      } else {
        results[safePath] = contents;
      }
      if (err) (errors || (errors = [])).push(err);
      if (queue === 0) return callback(errors, results);
    });
  };

  serverRequire.setBasePath = function(relPath) {
    return basePath = path.resolve(relPath);
  };

  readAndParseFile = function(path, parent, callback) {
    var contents;
    try {
      path = resolvePath(path, parent);
    } catch (err) {
      return callback(err, path, '');
    }
    if (loaded[path]) return;
    queue++;
    try {
      contents = fs.readFileSync(path, 'utf8');
      loaded[path] = true;
      findAndLoadSyncRequires(path, contents, callback);
      queue--;
      return callback(null, path, contents);
    } catch (err) {
      queue--;
      return callback(err, path, '');
    }
  };

  findAndLoadSyncRequires = function(filePath, contents, callback) {
    var dependencies, dependency, syncRequire, _i, _len, _results;
    dependencies = findRequires(contents, {
      raw: true
    });
    _results = [];
    for (_i = 0, _len = dependencies.length; _i < _len; _i++) {
      dependency = dependencies[_i];
      if ((syncRequire = dependency.value) != null) {
        _results.push(readAndParseFile(syncRequire, path.dirname(filePath), callback));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

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

  serverRequire.setBasePath('./');

  module.exports = serverRequire;

}).call(this);
