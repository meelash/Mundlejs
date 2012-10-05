http = require 'http'
fs = require 'fs'
mundleCoffee = require 'mundle-coffee-script'
mundleJade = require 'mundle-jade'

serverRequire = require '../../lib/server'
serverRequire.setBasePath './'
serverRequire.use mundleCoffee
serverRequire.use mundleJade

# Server
index = fs.readFileSync './index.html'
(server = http.createServer (req, res)->
  if req.url is '/'
    res.writeHead 200, 'Content-Type': 'text/html'
    res.end index
).listen 1337, '127.0.0.1'
serverRequire.listen server

console.log 'Server running at http://127.0.0.1:1337/'