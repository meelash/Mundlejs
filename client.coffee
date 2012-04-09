addRequireClientSide = ->
  bongo.api.Require::require = (path, callback)->
    if (exported = cache.modules[path])?
      callback? null, exported
      return exported
    else if (source = cache.fetched[path])?
      do ->
        module = exports : {}
        # exports = module.exports
        console.log "#{path} eval'ed"
        eval source
        exported = cache.modules[path] = module.exports
        callback? null, exported
        return exported
    else
      @serverRequire path, cache.cached, (err, sources)->
        for own subPath, source of sources
          console.log "#{subPath} fetched"
          cache.fetched[subPath] = source
          cache.cached[subPath] = yes
        callback null, require path

  cache =
    modules : {}
    fetched : {}
    cached  : {}

  requireObj = new bongo.api.Require
  window.require = requireObj.require.bind requireObj