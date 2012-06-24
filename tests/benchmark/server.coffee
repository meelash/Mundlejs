cluster = require 'cluster'
numCPUs = (require 'os').cpus().length

if cluster.isMaster
  for i in [1..numCPUs]
    cluster.fork()
else
  serverRequire = require 'mundle'

  serverRequire.setBasePath "#{__dirname}/testFiles"
  serverRequire.listen 3000, ->
    process.send ready : yes