fs = require 'fs'
{exec} = require 'child_process'
reporter = require('nodeunit').reporters.default

task 'test', 'Run the automated tests', ()->
  try
    fs.mkdirSync './tmp/'
    fs.mkdirSync './tmp/mundleTest'
    fs.mkdirSync './tmp/mundleTest/node_modules'
    fs.mkdirSync './tmp/mundleTest/node_modules/mundle'
    fs.mkdirSync './tmp/mundleTest/node_modules/mundle/lib'
    exec 'cp ./package.json ./tmp/mundleTest/node_modules/mundle'
  
    exec 'coffee -o ./tmp/mundleTest/node_modules/mundle/lib -c ./src/*.coffee
    && coffee -o ./tmp/mundleTest/ -c ./tests/main.coffee', ()->
      reporter.run ['./tmp/mundleTest/main.js'], null, ->
        exec 'rm -Rf ./tmp'
  catch error
    exec 'rm -Rf ./tmp'