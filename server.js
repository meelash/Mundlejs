(function() {
  var findAndLoadSyncRequires, fs, http, index, loaded, queue, readAndParseFile, resolvePath, serverRequire, url;

  http = require('http');

  url = require('url');

  fs = require('fs');

  index = fs.readFileSync('./index.html');

  (http.createServer(function(req, res) {
    var clientCacheDiff, clientJs, parsedUrl, path;
    if (req.url === '/') {
      res.writeHead(200, {
        'Content-Type': 'text/html'
      });
      return res.end(index);
    } else if (req.url === '/client.js') {
      clientJs = fs.readFileSync('./client.js');
      res.writeHead(200, {
        'Content-Type': 'text/script'
      });
      return res.end(clientJs);
    } else {
      parsedUrl = url.parse(req.url, true);
      if (req.headers.clientid != null) {
        path = parsedUrl.pathname.slice(1);
        clientCacheDiff = parsedUrl.query;
        return serverRequire(path, clientCacheDiff, function(err, results) {
          return res.end(JSON.stringify(results));
        });
      }
    }
  })).listen(1337, '127.0.0.1');

  console.log('Server running at http://127.0.0.1:1337/');

  loaded = {};

  queue = 0;

  serverRequire = function(path, loadedModules, callback) {
    var results;
    loaded = loadedModules;
    queue = 0;
    results = {};
    return readAndParseFile(path, function(path, contents) {
      results[path] = contents;
      if (queue === 0) return callback(null, results);
    });
  };

  readAndParseFile = function(path, callback) {
    var contents;
    if (loaded[path]) return;
    queue++;
    contents = fs.readFileSync("./" + path, 'utf8');
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
      if (requireLine != null) {
        _results.push(readAndParseFile(requireLine[1], callback));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  resolvePath = function() {};

}).call(this);
