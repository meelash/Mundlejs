#!/usr/bin/env node

process.env['bower_directory'] = 'mundles';

var semver         = require('semver');
var nopt           = require('nopt');
var path           = require('path');
var pkg            = require('bower/package.json');
var updateNotifier = require('update-notifier');

var template = require('bower/lib/util/template');
var bower    = require('bower');

var command;
var options;
var shorthand;
var input   = process.argv;
var nodeVer = process.version;
var reqVer  = pkg.engines.node;
var errors = [];
var notifier = updateNotifier({ packageName: pkg.name, packageVersion: pkg.version });

if (notifier.update) {
  process.stderr.write(template('update-notice', notifier.update, true));
}

process.title = 'mundle';

if (reqVer && !semver.satisfies(nodeVer, reqVer)) {
  throw new Error('Required: node ' + reqVer);
}

shorthand = { 'v': ['--version'] };
options   = { version: Boolean };
options   = nopt(options, shorthand, process.argv);

bower.version = pkg.version;

if (options.version) return console.log(bower.version);

command = options.argv.remain && options.argv.remain.shift();
command = bower.abbreviations[command];

if (command) bower.command = command;


// Temporarory fix for #22 #320 #187
var errStatusHandler = function () {
  process.removeListener('exit', errStatusHandler);
  process.exit(errors.length ? 1 : 0);
};
process.on('exit', errStatusHandler);

bower.commands[bower.command || 'help'].line(input)
  .on('data', function (data) {
    if (data) process.stdout.write(data);
  })
  .on('end', function (data) {
    if (data) process.stdout.write(data);
  })
  .on('warn', function (warning)  {
    process.stderr.write(template('warn', { message: warning }, true));
  })
  .on('error', function (err)  {
    if (options.verbose) throw err;
    process.stdout.write(template('error', { message: err.message }, true));
    errors.push(err);
  });