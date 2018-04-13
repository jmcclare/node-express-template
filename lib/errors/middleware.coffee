# 
# Middleware for handling common errors.
# 
# Part of this code is based on visionmedia's error-pages example:
# https://github.com/visionmedia/express/tree/master/examples/error-pages
# 

errors = require './errors'

# 
# Catch unhandled paths and try redirecting them to the same url with a '/' on
# the end. This lets you use routes that only work with a trailing slash
# without inconveniencing your users.
# 
# This must be used after any routes or request handlers.
# 
addSlash = (req, res, next) ->

  # Assume any url ending in .xxx is a static file request and don't try
  # adding a trailing slash.
  if req.method == "GET" &&
  req.path[ req.path.length - 1 ] != "/" &&
  req.path[ req.path.length - 4 ] != '.'
    queryString = if req._parsedUrl.search then req._parsedUrl.search else ''
    # You can also do this:
    #   queryString = `req._parsedUrl.search ? req._parsedUrl.search : ''`
    return res.redirect(301, req.path + '/' + queryString)

  next()


# 
# Catch unhandled paths and try redirecting them to the same url without a '/'
# on the end. This lets you use routes that only work without a trailing slash
# without inconveniencing your users.
#
# NOTE: You must also enable 'strict routing' to make sure non trailing slash
# URLs don't match with a slash.
# 
# This must be used after any routes or request handlers.
# 
removeSlash = (req, res, next) ->

  # Assume any url ending in .xxx is a static file request and don't try
  # adding a trailing slash.
  if req.method == "GET" &&
  req.path[ req.path.length - 1 ] == "/"
    queryString = if req._parsedUrl.search then req._parsedUrl.search else ''
    # You can also do this:
    #   queryString = `req._parsedUrl.search ? req._parsedUrl.search : ''`
    return res.redirect 301, req.path.substring(0, req.path.length - 1) + queryString

  next()


# 
# notFound - 404 error handler.
# 
# Uses the main layout.jade to display nothing but a friendly message when the
# requested page cannot be found.
# 
# This must be used by the app after any routes or path handlers; ie. `app.use
# notFound` must come after `app.use app.router` and `app.use express.static`.
# That way, if Express gets to this middleware we can assume we are dealing
# with a 404.
# 
notFound = (req, res, next) ->
  res.status 404
  
  # respond with html page
  if req.accepts 'html'
    return res.render 'errors/404',
      title: "404 Not Found",
      section: '404'

  # respond with json
  if req.accepts 'json'
    return res.send error: 'Not found'

  # default to plain-text. send()
  return res.type('txt').send 'Not found'


# 
# forbidden - 403 error handler.
# 
# Uses the main layout.jade to display nothing but a friendly message when the
# requested page cannot be shown to the user.
#
# The standard message we show states that the user must be logged in with the
# proper permissions to view this page. This is our most common reason for
# showing this error. Note that to truly hide a resource from users who cannot
# access it you should return a 404 and pretend the resource does not exist.
#
# Use this instead of res.render from any route that wants to return a 403
# error.
# 
forbidden = (req, res, next) ->
  res.status 403
  
  # respond with html page
  if req.accepts 'html'
    return res.render 'errors/403',
      title: "403 Forbidden",
      section: '403'

  # respond with json
  if req.accepts 'json'
    return res.send error: 'Forbidden'

  # default to plain-text. send()
  return res.type('txt').send 'Forbidden'


#
# nonFatal - Non Fatal Error Handler
#
# If err is one of a list of non-fatal types that can be handled with a less
# alarming message to the user, this will call an appropriate non-error
# handler. Otherwise, it passes the request on to the next error handling
# middleware.
#
nonFatal = (err, req, res, next) ->
  if err instanceof errors.ForbiddenError
    return forbidden req, res, next

  return next err


# 
# serverError - Server Error handler
# 
# Displays a simple, user friendly server error page with the
# full error message in hidden markup.
# 
# This should be used after any other middleware.
# 
serverError = (err, req, res, next) ->
  # we may use properties of the error object here and next(err) appropriately
  # or, if we possibly recovered from the error, serverError next().

  res.status err.status || 500

  # respond with html page
  #
  # We use a simple template that doesn't reference any external CSS, JS or
  # images.
  #
  # It does use the error object to print the full error message in a hidden
  # pre element. This could possibly cause this template itself to produce an
  # error if the format of the err object changes, but that is not likely and
  # Node would at least spit out it's default server error message until it's
  # fixed.
  if req.accepts 'html'
    return res.render 'errors/500',
      error: err
      status: err.status || 500

  # respond with json
  if req.accepts 'json'
    return res.send error: 'Internal Server Error'

  # default to plain-text. send()
  return res.type('txt').send 'Internal Server Error'


module.exports =
  notFound: notFound
  forbidden: forbidden
  nonFatal: nonFatal
  serverError: serverError
  addSlash: addSlash
  removeSlash: removeSlash
