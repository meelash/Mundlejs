http = require 'http'
url = require 'url'
fs = require 'fs'

# Server
index = fs.readFileSync './index.html'
(http.createServer (req, res)->
  if req.url is '/'
    res.writeHead 200, 'Content-Type': 'text/html'
    res.end index
  else if req.url is '/client.js'
    clientJs = fs.readFileSync './client.js'
    res.writeHead 200, 'Content-Type' : 'text/script'
    res.end clientJs
  else
    parsedUrl = url.parse req.url, yes
    if req.headers.clientid?
      path = parsedUrl.pathname[1...]
      clientCacheDiff = parsedUrl.query
      serverRequire path, clientCacheDiff, (err, results)->
        res.end JSON.stringify results
).listen 1337, '127.0.0.1'
console.log 'Server running at http://127.0.0.1:1337/'



# Require
cachedPkgs = {}
loaded = {}
queue = 0

serverRequire = (path, loadedModules, callback)->
  loaded = loadedModules
  queue = 0
  results = {}
  readAndParseFile path, (path, contents)->
    results[path] = contents
    if queue is 0
      callback null, results

readAndParseFile = (path, callback)->
  return if loaded[path]
  queue++
  contents = fs.readFileSync (resolvePath path), 'utf8'
  loaded[path] = yes
  findAndLoadSyncRequires contents, callback
  queue--
  callback path, contents

findAndLoadSyncRequires = (contents, callback)->
  lines = contents.split '\n'
  results = []
  for line in lines
    requireLine = (line.match /require\('(.*)'\)/)
    if requireLine?
      readAndParseFile requireLine[1], callback

resolvePath = (path)->
  "./#{path}"

cachePath = (path)->
  
