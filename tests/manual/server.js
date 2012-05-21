(function() {
  var fs, http, index, server, serverRequire;

  http = require('http');

  fs = require('fs');

  serverRequire = require('../../lib/server');

  serverRequire.setBasePath('./');

  index = fs.readFileSync('./index.html');

  (server = http.createServer(function(req, res) {
    if (req.url === '/') {
      res.writeHead(200, {
        'Content-Type': 'text/html'
      });
      return res.end(index);
    }
  })).listen(1337, '127.0.0.1');

  serverRequire.listen(server);

  console.log('Server running at http://127.0.0.1:1337/');

}).call(this);
