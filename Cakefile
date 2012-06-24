fs = require 'fs'
{exec} = require 'child_process'
reporter = require('nodeunit').reporters.default

process.on 'exit', ->
  exec 'rm -Rf ./tmp'

task 'test', 'Run the automated tests', ()->
  try
    fs.mkdirSync './tmp/'
    fs.mkdirSync './tmp/mundleTest'
    fs.mkdirSync './tmp/mundleTest/node_modules'
    fs.mkdirSync './tmp/mundleTest/node_modules/mundle'
    fs.mkdirSync './tmp/mundleTest/node_modules/mundle/lib'
    exec 'cp ./package.json ./tmp/mundleTest/node_modules/mundle'
    exec 'cp ./tests/index.html ./tmp/mundleTest'
  
    exec 'coffee -o ./tmp/mundleTest/node_modules/mundle/lib -c ./src/*.coffee
    && coffee -o ./tmp/mundleTest/ -c ./tests/main.coffee', ()->
      reporter.run ['./tmp/mundleTest/main.js'], null, ->
        exec 'rm -Rf ./tmp'
  catch error
    exec 'rm -Rf ./tmp'

task 'benchmark', 'Benchmark serving files', ()->
  try
    fs.mkdirSync './tmp/'
    fs.mkdirSync './tmp/mundleBenchmark'
    fs.mkdirSync './tmp/mundleBenchmark/node_modules'
    fs.mkdirSync './tmp/mundleBenchmark/node_modules/mundle'
    fs.mkdirSync './tmp/mundleBenchmark/node_modules/mundle/lib'
    exec 'cp ./package.json ./tmp/mundleBenchmark/node_modules/mundle'
    exec 'cp -r ./tests/benchmark/testFiles ./tmp/mundleBenchmark'
    
    
    exec 'coffee -o ./tmp/mundleBenchmark/node_modules/mundle/lib -c ./src/*.coffee
    && coffee -o ./tmp/mundleBenchmark/ -c ./tests/benchmark/*.coffee', ()->
      require './tmp/mundleBenchmark/main.js'
  catch error
    exec 'rm -Rf ./tmp'