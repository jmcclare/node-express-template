# 
# Module dependencies.
# 

# Node packages
bodyParser = require 'body-parser'
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy

# local libraries
urls = require 'urls'
User = require('users').data.User
Role = require('users').data.Role


passport.use new LocalStrategy (username, password, done) ->
  User.findOne username: username, (err, user) ->
    if err
      console.log 'Error finding user for login.'
      return done err
    if ! user
      return done null, false, message: 'Incorrect username.'
    user.comparePassword password, (err, isMatch) ->
      if err
        return done err
      if isMatch
        return done null, user
      else
        return done null, false, message: 'Incorrect password.'


passport.serializeUser (user, done) ->
  done null, user.username


passport.deserializeUser (id, done) ->
  User.findOne username: id, (err, user) ->
    if err
      return done err
    if user
      user.populate 'roles', (err, user) ->
        if err
          return done err
        return done null, user
    else
      return done null, null


addPassport = (app) ->
  app.use passport.initialize()
  app.use passport.session()


routes =
  assign: (app, parentPath) ->
    parentPath = "/auth"  unless parentPath
    if ! app.locals.urls
      urls.addHelpers app
    app.locals.urls['login'] = parentPath + "/login"
    app.locals.urls['logout'] = parentPath + "/logout"

    # Factoring this out.
    title = 'Login'
    section = 'login'
    alertMessages = ''
    successMessages = ''
    errorMessages = ''
    fieldErrors =
      username: ''
      password: ''

    app.get app.locals.urls['login'], (req, res, next) ->
      res.render 'auth/login',
        title: 'Login'
        subTitle: ''
        section: 'auth'

    app.post app.locals.urls['login'],
      bodyParser.urlencoded({extended: false}),
      # TODO: Set a post-login URL based on the page the login form was
      # originally submitted from.
      passport.authenticate 'local',
        successRedirect: app.locals.urls['home']
        failureRedirect: app.locals.urls['login']
        failureFlash: true

    app.get app.locals.urls['logout'], (req, res, next) ->
      req.session.destroy (err) ->
        if err
          console.log err
        return res.redirect(app.locals.url 'login')


addHelpers = (app) ->
  app.locals.permissions = {}

  #
  # mergePermissions
  #
  # Merge dictionaries of permissions into the full list stored in app.locals.
  # Packages that use permissions should merge them into this full list so that
  # administration interfaces can display them for assignment.
  #
  # permissions - dictionary of permissions to be merged.
  #
  app.locals.mergePermissions = (permissions) ->
    for key of permissions
      app.locals.permissions[key] = permissions[key]


  #
  # hasPermission
  #
  # Determines whether or not a request has a permission.
  #
  # req - a request object
  # permission - string - name of the permission to be checked
  # cb - function that takes two parameters:
  #   err - any unhandled error encountered by hasPermission, or null
  #   hasPermission - boolean - whether or not the user has the permission
  #
  app.locals.hasPermission = (req, permission, cb) ->
    # Factor this logic out to avoid repeating it below.
    checkUser = ->
      if req.user
        # See if current user has this permission.
        req.user.hasPermission permission, (err, hasPermission) ->
          #console.log 'req.user.hasPermission callback.'
          #console.log 'err: ' + err + ', hasPermission: ' + hasPermission
          if err
            return cb err, false
          return cb null, hasPermission
      else
        # Finally, return false by default
        return cb null, false

    #console.log 'inside app.locals.hasPermission callback.'
    # See if 'everyone' role has this permission.
    # We grant all site visitors the permissions of the 'everyone' role, if it
    # exists.
    Role.findOne name: 'everyone', (err, role) ->
      if err
        return cb err, false
      if role
        role.hasPermission permission, (err, hasPermission) ->
          if err
            return cb err, false
          if hasPermission
            return cb null, true
          return checkUser()
      else
        return checkUser()


module.exports =
  routes: routes
  addPassport: addPassport
  addHelpers: addHelpers
