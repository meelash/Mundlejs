cluster = require 'cluster'
http = require 'http'
numCPUs = require('os').cpus().length

if cluster.isMaster
  for i in [1..4]
    cluster.fork()

else
  options =
    port : 3000
    path : '/mundlejs/KDApplications/Home.kdapplication/AppController'
    method : 'GET'
    headers : clientId : 'lakjsdflkjasld'

  i = 0
  total = 0
  asyncLoop = ->
    unless ++i > 100
      # buffer = ""
      req = http.request options, (res)->
        # res.on 'data', (chunk)->
          # buffer += chunk
        res.on 'end', ->
          # {err, results} = JSON.parse buffer.toString()
          # console.log err, Object.keys results
          console.log total += Date.now()-startTime
          asyncLoop()

      req.on 'error', (e)->
        console.log 'problem with request: ' + e.message
    
      req.end()
      startTime = Date.now()
    else
      console.log total/i
      process.send done : yes
  asyncLoop()