Copyright (c) 2012, Koding, Inc.
Author : Saleem Abdul Hamid <meelash@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


class Require extends bongo.Model  
  serverRequire:(path, loadedModules, callback)->
    if Array.isArray path then return @requireJsCompatible path, loadedModules, callback
    foo = @
    foo.loaded = loadedModules
    foo.queue = 0
    results = {}
    @readAndParseFile path, (path, contents)->
      results[path] = contents
      if foo.queue is 0
        callback null, results
  
  readAndParseFile:(path, callback)->
    return if @loaded[path]
    @queue++
    contents = fs.readFileSync path, 'utf8'
    @loaded[path] = yes
    @findAndLoadSyncRequires contents, callback
    @queue--
    callback path, contents
  
  findAndLoadSyncRequires:(contents, callback)->
    lines = contents.split '\n'
    results = []
    for line in lines
      requireLine = (line.match /require\('(.*)'\)/)
      if requireLine?
        @readAndParseFile requireLine[1], callback
  
  #incomplete, need to handle requirejs #define somehow (meh) -3/9/12 sah
  requireJsCompatible:(paths, loadedModules, callback)->
    results = {}
    queue = paths.length
    for path in paths
      @serverRequire path, loadedModules, (err, partialResults)->
        _.extend results, partialResults
        if --queue is 0 then callback null, results
