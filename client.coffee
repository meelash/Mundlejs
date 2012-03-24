window.require = (path, callback)->
  if (exported = cache.modules[path])?
    callback? null, exported
    return exported
  else if (source = cache.fetched[path])?
    do ->
      module = exports : {}
      console.log "#{path} eval'ed"
      eval source
      exported = cache.modules[path] = module.exports
      callback? null, exported
      return exported
  else
    serverRequire path, (err, sources)->
      for own subPath, source of sources
        console.log "#{subPath} fetched"
        cache.fetched[subPath] = source
        cache.cached[subPath] = yes
      callback? null, require path

serverRequire = (path, callback)->
  request = new XMLHttpRequest()
  request.open('GET', "http://127.0.0.1:1337/#{path}?#{cacheDiffString()}", true)
  request.setRequestHeader 'clientid', 'lakjsdflkjasld'
  request.responseType = 'text'
  request.onload = ->
    callback null, JSON.parse request.response
  request.send()

cacheDiffString = ->
  (Object.keys cache.cached).join '=1&' + '=1'

cache =
  modules : {}
  fetched : {}
  cached  : {}
