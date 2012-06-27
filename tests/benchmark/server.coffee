cluster = require 'cluster'
numCPUs = (require 'os').cpus().length

if cluster.isMaster
  for i in [1..numCPUs]
    cluster.fork()
else
  serverRequire = require 'mundle'

  serverRequire.setBasePath "#{__dirname}/testFiles/separate"
  serverRequire.listen 3000, ->
    process.send ready : yes

# cluster = require 'cluster'
# numCPUs = (require 'os').cpus().length
# connect = require 'connect'
# http = require 'http'
# 
# if cluster.isMaster
#   for i in [1..numCPUs]
#     cluster.fork()
# else
#   app = connect()
#     .use connect.static "#{__dirname}/testFiles/concatenated"
#   
#   (http.createServer app).listen 3000