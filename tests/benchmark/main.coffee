{fork} = require 'child_process'

serverProc = fork "#{__dirname}/server"

serverProc.on 'message', (message)->
  # if message.ready
  #   clientProc = fork "#{__dirname}/client"
  #   
  #   clientProc.on 'message', (message)->
  #     if message.done
  #       process.exit()