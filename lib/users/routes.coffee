# 
# Module dependencies.
# 

# local libraries
urls = require 'urls'
User = require('./data').User
permissions = require './permissions'
errors = require('errors').errors


#
# Assign our default set of routes to the app under parentPath, or the
# default parentPath.
#
assign = (app, parentPath) ->
  parentPath = "/users" unless parentPath
  if ! app.locals.urls
    urls.addHelpers app
  app.locals.urls['users.index'] = parentPath
  app.locals.urls['users.view'] = parentPath + "/:username"

  app.locals.mergePermissions permissions

  app.get app.locals.urls['users.index'], (req, res, next) ->
    app.locals.hasPermission req, 'viewUsersList', (err, hasPermission) ->
      if err
        return next()
      if ! hasPermission
        err = new errors
          .ForbiddenError 'You are not authorized to view the list of users.'
        return next err
      User.find null, (err, users) ->
        if err
          # No users found. Pass to the next route / middleware; probably the
          # catch-all 404 handler.
          return next()
        res.render 'users/index',
          title: 'Users'
          subTitle: 'A List of User Objects'
          section: 'users'
          users: users
  

  app.get app.locals.urls['users.view'], (req, res, next) ->
    tryRender = ->
      User.findOne username: req.params.username, (err, user) ->
        if err
          # username not found. Pass to the next route / middleware; probably the
          # catch-all 404 handler.
          return next()
        user.populate 'roles', (err, user) ->
          if err
            return next()
          return res.render 'users/view',
            title: user.fullName
            subTitle: user.fullName + "'s Profile"
            section: 'users'
            user: user

    # Check permissions
    app.locals.hasPermission req, 'viewUserProfiles', (err, hasPermission) ->
      if err
        return next()
      if hasPermission
        return tryRender()
      if req.user
        if req.user.username == req.params.username
          # The current user can always view her own profile
          return tryRender()
      err = new errors
        .ForbiddenError 'You are not authorized to view user profiles.'
      return next err


module.exports = assign: assign
