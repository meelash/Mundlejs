http = require 'http'
url = require 'url'
fs = require 'fs'
serverRequire = require '../../lib/server.js'
serverRequire.setBasePath './'

# Server
index = fs.readFileSync './index.html'
(http.createServer (req, res)->
  if req.url is '/'
    res.writeHead 200, 'Content-Type': 'text/html'
    res.end index
  else if req.url is '/client.js' 
    clientJs = fs.readFileSync '../../lib/client.js'
    res.writeHead 200, 'Content-Type' : 'text/script'
    res.end clientJs
  else
    parsedUrl = url.parse req.url, yes
    if req.headers.clientid?
      path = parsedUrl.pathname[1...]
      clientCacheDiff = parsedUrl.query
      serverRequire path, clientCacheDiff, (err, results)->
        res.end JSON.stringify {err, results}
).listen 1337, '127.0.0.1'
console.log 'Server running at http://127.0.0.1:1337/'