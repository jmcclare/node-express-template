#
# Takes a url pattern (as used by an Express route) and a dictionary of
# parameters for it and returns the full path to the resource.
# 
# Code borrowed from:
# http://stackoverflow.com/questions/10027574/express-js-reverse-url-route-django-style
# 
reverse = (url, params) ->
  return url.replace /(\/:\w+\??)/g, (m, c) ->
    c = c.replace /[/:?]/g, ''
    #return params[c] ? '/' + params[c] : ""
    if params[c]
      return '/' + params[c]
    else return ''

addHelpers = (app) ->
  # Initialize the urls dictionary.
  app.locals.urls = home: '/'

  app.locals.url = (name, params={}) ->
    if name of app.locals.urls
      return reverse app.locals.urls[name], params
    return ''

module.exports = addHelpers: addHelpers
