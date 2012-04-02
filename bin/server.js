(function() {
  var cachePath, cachedPkgs, findAndLoadSyncRequires, findRequires, fs, loaded, queue, readAndParseFile, resolvePath, serverRequire;

  fs = require('fs');

  findRequires = require('find-requires');

  cachedPkgs = {};

  loaded = {};

  queue = 0;

  serverRequire = function(path, loadedModules, callback) {
    var errors, results;
    loaded = loadedModules;
    queue = 0;
    results = {};
    errors = null;
    return readAndParseFile(path, function(err, path, contents) {
      results[path] = contents;
      if (err) (errors || (errors = [])).push(err);
      if (queue === 0) return callback(errors, results);
    });
  };

  readAndParseFile = function(path, callback) {
    var contents;
    if (loaded[path]) return;
    queue++;
    try {
      contents = fs.readFileSync(resolvePath(path), 'utf8');
      loaded[path] = true;
      findAndLoadSyncRequires(contents, callback);
      queue--;
      return callback(null, path, contents);
    } catch (err) {
      queue--;
      return callback(err, path, '');
    }
  };

  findAndLoadSyncRequires = function(contents, callback) {
    var dependencies, dependency, syncRequire, _i, _len, _results;
    dependencies = findRequires(contents, {
      raw: true
    });
    _results = [];
    for (_i = 0, _len = dependencies.length; _i < _len; _i++) {
      dependency = dependencies[_i];
      if ((syncRequire = dependency.value) != null) {
        _results.push(readAndParseFile(syncRequire, callback));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  resolvePath = function(path) {
    return "./" + path;
  };

  cachePath = function(path) {};

  module.exports = serverRequire;

}).call(this);
