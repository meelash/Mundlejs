fs = require 'fs'
{exec} = require 'child_process'
reporter = require('nodeunit').reporters.default

# Cleanup temporary files if anything goes wrong
process.on 'exit', ->
	exec 'rm -Rf ./tmp'

task 'test', 'Run the automated tests', ()->
	try
		# Create the temporary directory in which mundle will be installed
		fs.mkdirSync './tmp/'
		fs.mkdirSync './tmp/mundleTest'
		# create mundle folders in the node_modules folder of the temp directory
		fs.mkdirSync './tmp/mundleTest/node_modules'
		fs.mkdirSync './tmp/mundleTest/node_modules/mundle'
		fs.mkdirSync './tmp/mundleTest/node_modules/mundle/lib'
		# copy the sample mundle from the tests directory to the temp directory
		exec 'cp -r ./tests/mundles ./tmp/mundleTest'
		# copy the test index to the temp directory
		exec 'cp ./tests/index.html ./tmp/mundleTest'
		
		# "install" mundle by compiling the relevant files and placing them in their appropriate locations
		exec 'cp ./package.json ./tmp/mundleTest/node_modules/mundle'
		exec 'cp ./lib/* ./tmp/mundleTest/node_modules/mundle/lib
		&& coffee -o ./tmp/mundleTest/ -c ./tests/main.coffee
		&& coffee -bo ./tmp/mundleTest/node_modules/mundle/lib/exposed -c ./src/server.coffee', ()->
			# with environment completely set up, start the tests
			process.chdir('./tmp/mundleTest')
			reporter.run ['./main.js'], null, (err)->
				# when complete, remove the temporary directory
				exec 'cd ../.. && rm -Rf ./tmp'
				if err
					process.exit(1)
				process.exit(0)
	catch error
		# if anything goes wrong, clean up the temporary directory
		exec 'rm -Rf ./tmp'

task 'build', 'Build the javascript output', ()->
	exec 'coffee -o ./lib/ -c ./src/*.coffee'

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