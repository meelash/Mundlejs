var fs, http, index, serverRequire, url;

http = require('http');

url = require('url');

fs = require('fs');

serverRequire = require('../bin/server.js');

index = fs.readFileSync('./index.html');

(http.createServer(function(req, res) {
  var clientCacheDiff, clientJs, parsedUrl, path;
  if (req.url === '/') {
    res.writeHead(200, {
      'Content-Type': 'text/html'
    });
    return res.end(index);
  } else if (req.url === '/client.js') {
    clientJs = fs.readFileSync('../bin/client.js');
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
        return res.end(JSON.stringify({
          err: err,
          results: results
        }));
      });
    }
  }
})).listen(1337, '127.0.0.1');

console.log('Server running at http://127.0.0.1:1337/');