// Generated by CoffeeScript 1.3.3
(function() {
  var fs, http, index, mundleCoffee, mundleJade, server, serverRequire;

  http = require('http');

  fs = require('fs');

  mundleCoffee = require('mundle-coffee-script');

  mundleJade = require('mundle-jade');

  serverRequire = require('../../lib/server');

  serverRequire.setBasePath('./');

  serverRequire.use(mundleCoffee);

  serverRequire.use(mundleJade);

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
