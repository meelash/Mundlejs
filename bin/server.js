(function() {
  var cachePath, cachedPkgs, findAndLoadSyncRequires, fs, loaded, queue, readAndParseFile, resolvePath, serverRequire;
  fs = require('fs');
  cachedPkgs = {};
  loaded = {};
  queue = 0;
  serverRequire = function(path, loadedModules, callback) {
    var results;
    loaded = loadedModules;
    queue = 0;
    results = {};
    return readAndParseFile(path, function(path, contents) {
      results[path] = contents;
      if (queue === 0) {
        return callback(null, results);
      }
    });
  };
  readAndParseFile = function(path, callback) {
    var contents;
    if (loaded[path]) {
      return;
    }
    queue++;
    contents = fs.readFileSync(resolvePath(path), 'utf8');
    loaded[path] = true;
    findAndLoadSyncRequires(contents, callback);
    queue--;
    return callback(path, contents);
  };
  findAndLoadSyncRequires = function(contents, callback) {
    var line, lines, requireLine, results, _i, _len, _results;
    lines = contents.split('\n');
    results = [];
    _results = [];
    for (_i = 0, _len = lines.length; _i < _len; _i++) {
      line = lines[_i];
      requireLine = line.match(/require\('(.*)'\)/);
      _results.push(requireLine != null ? readAndParseFile(requireLine[1], callback) : void 0);
    }
    return _results;
  };
  resolvePath = function(path) {
    return "./" + path;
  };
  cachePath = function(path) {};
  module.exports = serverRequire;
}).call(this);
