# standard packages

fs = require 'fs'
path = require 'path'


# npm packages

# Place debug calls in this file under 'config'
debug = require('debug')('config')
express = require 'express'
session = require 'express-session'
cookieParser = require 'cookie-parser'
methodOverride = require 'method-override'
bodyParser = require 'body-parser'
flash = require 'connect-flash'
stylus = require 'stylus'
nib = require 'nib'
CoffeeScript = require 'coffee-script'
connectAssets = require 'connect-assets'

redis = require 'redis'
RedisStore = require('connect-redis')(session)
redisClient = redis.createClient()
redisClient.on 'error', (err)->
  # We only show the error in debug. If Redis is not running at all we will
  # find out below in checkRedis.
  debug err


# local packages

urls = require 'urls'
defaults = require './defaults'
routes = require './routes'
errMw = require('errors').middleware
auth = require 'auth'
helpers = require 'helpers'
upload = require 'upload'


module.exports = (app) ->

  # Default starting options
  options =
      redisAvailable: false

  checkRedis app, options, configureApp


# Initializes Redis and sends it a test query to see if it is up and running.
#
# Call this before configureApp to have the redisAvailable option set properly.
#
# If you do not have Redis on your system, this software will default to
# storing sessions in memory. Note that the default memory session store is
# known to leak and should not be used in production. In production, you must
# either have Redis available or modify this software to not use sessions at
# all.
checkRedis = (app, options, cb)->

  # Send a query for a random key name. It doesn't matter if the key exists or
  # not. Redis will only pass an error to the callback if it encounters a
  # problem. If the key doesn't exist the reply will be null. If there is an
  # error, it means Redis is having a serious problem. We will assume it is not
  # available in that case.
  redisClient.get 'somekeythatprobablydoesntexist', (err, reply)->
    if err
      debug 'Error getting random key from Redis. Assuming Redis not available.'
      options.redisAvailable = false
    else
      debug 'No error getting random key from Redis. Assuming Redis available.'
      options.redisAvailable = true

    # Pass null error because we handle any Redis errors above.
    cb null, app, options


configureApp = (err, app, options)->
  oneDay = 86400000

  if err
    debug 'Error encountered before configureApp:'
    debug err

  # Determine the name of the site config file, if any.
  #
  # TODO: Add a settings file for the current site. Start by copying
  # site.coffee.ex to site.coffee. Edit that to fit the current site's
  # settings. You can also symlink it into this directory.
  localConfigFileName = path.join __dirname, 'site.coffee'
  try
    fs.openSync localConfigFileName, 'r'
  catch e
    localConfigFileName = path.join __dirname, 'site.js'
    try
      fs.openSync localConfigFileName, 'r'
    catch e
      localConfigFileName = null

  # Bring in the site specific regular (non-error) config
  if localConfigFileName
    require(localConfigFileName).regular app

  # Bring in the general environment specific regular (non-error) config
  #
  # This was the old documented way to fetch the env.
  #if ('development' == app.get 'env')
  #
  # The 3.0 to 4.0 migration docs said to check the variable this way.
  if ('development' == process.env.NODE_ENV)
    require('./development').regular app
  # Make production settings the default
  else
    require('./production').regular app

  # Overwrite the default CoffeeScript compile function connectAssets gets from
  # Snockets to add the `bare` option.
  # The CoffeeScript 'top-level function safety wrapper' was causing huge
  # problems for my AngularJS application, which needed to create global
  # functions in separate source files. I found out later that if you follow
  # the Angular seed template, you shouldn't be affected by this, but you will
  # still keep the global scope clean even without the safety wrapper. This fix
  # is left here to prevent other possible problems.
  #
  # I checked the connectAssets source code to find out how to set a different
  # JS compiler function (it gets the default from Snockets), Snockets to find
  # out what it's default compiler function is, and connect-coffee-script to
  # find out how to pass the `bare` option to `compile`.
  jsCompilers =
    coffee:
      match: /\.js$/
      compileSync: (sourcePath, source) ->
        CoffeeScript.compile source, {filename: sourcePath, bare: true}
  app.use connectAssets
    # This option will only be used in production mode.
    # The path will be relative to the directory server.coffee is in. More
    # accurately, it probably uses process.cwd() to get the current directory.
    # This will return whatever directory the process that started the server
    # was in. For this reason, you must `cd` to server.coffee's directory
    # before starting it.
    buildDir: 'public'
    jsCompilers: jsCompilers
  app.set 'views', __dirname + '/../views'
  # Tell Express to look for a .jade file and render it with the jade engine
  # when told to render a name with no extension.
  app.set 'view engine', 'jade'

  # As of Express 4.0 bodyParser comes in a separate library and it does not
  # handle multipart forms (which is good because it was bad at them).
  # It's better to add this middleware only to routes that need it. Uncomment
  # it here if you want req.body fields available in all post routes.
  #app.use bodyParser.urlencoded { extended: false }

  # TODO: set these secrets to your own random strings
  app.use cookieParser("secret")

  # To use store sessions in memory, remove the `store:` option we pass in
  # here.
  # As you can see, it will automatically use the in-memory store when Redis is
  # not available.
  #app.use express.session
  sessionOptions =
    secret: "secret"
    resave: true
    saveUninitialized: true
    cookie:
      path: '/'
      httpOnly: true
      maxAge: null
  if options.redisAvailable
    debug 'Adding RedisStore to session options.'
    sessionOptions.store = new RedisStore
      host: 'localhost'
      port: '6379'
      client: redisClient
  app.use session sessionOptions

  app.use flash()
  auth.addPassport app
  app.use methodOverride()
  app.use express.static path.join(app.root, 'public'),
    maxAge: oneDay
  urls.addHelpers app
  auth.addHelpers app
  helpers.addHelpers app

  # Add safe defaults for variables used by all templates.
  # This must be used before app.router.
  # Express 4.0 update: I think now these must simply be set before any routes
  # are added.
  defaults app

  # Make sure the upload temp dir exists and that the upTmp variable is set.
  #
  # upTmp defaults to /tmp/node-upload. If you want something else, set it like
  # this before you call setUpTmp:
  #   app.set 'upTmp', '/tmp/my-uploads'
  # TODO: make upTmp an environment variable that is used here if it exists.
  upload.setUpTmp app

  # Normally, a request for `/contact/` would match a route with URL
  # `/contact`.  With strict routing, the request will not match that route.
  # Even without strict routing, a request for `/contact` will not match a
  # route with URL `/contact/`.
  # NOTE: as of Express 4.0, this setting doesn't work here. It only works when
  # you pass it to a new router and use that.
  app.enable('strict routing')
  # As of Express 4.0 you no longer need to call app.router in your code.
  # Now you must add your routes in the same spot you used to call app.router
  #app.use app.router

  # Add the routes
  routes app

  #app.use errMw.addSlash
  # With this and strict routing, we are going with no trailing slashes in our
  # URLs.
  app.use errMw.removeSlash
  app.use errMw.notFound

  app.use errMw.nonFatal

  # Bring in the site specific error config
  if localConfigFileName
    require(localConfigFileName).error app

  # Bring in the general environment specific error config
  #
  # This was the old documented way to fetch the env.
  #if ('development' == app.get 'env')
  #
  # The 3.0 to 4.0 migration docs said to check the variable this way.
  if ('development' == process.env.NODE_ENV)
    require('./development').error app
  # Make production settings the default
  else
    require('./production').error app
