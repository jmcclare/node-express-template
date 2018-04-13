#
# Module dependencies.
#

# local libraries
urls = require 'urls'
Article = require('./data').Article
permissions = require './permissions'
errors = require('errors').errors
articleErrors = require './errors'
input = require './input'
artUtils = require './utilities'


#
# Assign our default set of routes to the app under parentPath, or the
# default parentPath.
#
assign = (app, parentPath) ->

  parentPath = "/articles" unless parentPath
  if ! app.locals.urls
    urls.addHelpers app

  app.locals.articlesApp = {} if !app.locals.articlesApp


  app.locals.articlesApp.itemsPerPage = 10

  app.locals.mergePermissions permissions.permissions


  # Regular URLs users will see in their browser's address bar.
  app.locals.urls['articles.index'] = parentPath
  app.locals.urls['articles.create'] = parentPath + "/create"
  app.locals.urls['articles.view'] = parentPath + "/:slug"
  app.locals.urls['articles.edit'] = parentPath + "/edit/:slug"
  app.locals.urls['articles.delete'] = parentPath + "/delete/:slug"

  # Unlike most partials for AngularJS apps, these are fully rendered HTML with
  # nothing left for Angular variables to fill in.
  partialsPath = parentPath + '/_partials'
  app.locals.urls['articles.partials.index'] = partialsPath + "/index"
  #app.locals.urls['articles.partials.create'] = partialsPath + "/create/"
  app.locals.urls['articles.partials.view'] = partialsPath + "/view/:slug"
  #app.locals.urls['articles.partials.edit'] = partialsPath + "/edit/:slug/"
  #app.locals.urls['articles.partials.delete'] = partialsPath + "/delete/:slug/"

  # The API for editing and retrieving articles. Default response format is
  # JSON.
  apiPath = parentPath + '/_api'
  # Return a list for GET. Add new item for POST.
  app.locals.urls['articles.api.index'] = apiPath
  # Return item for GET. Update for PUT. Delete for DELETE.
  app.locals.urls['articles.api.item'] = apiPath + "/:slug"

  # 'ngtpl' means 'Angular template'. These responses are meant only to be used
  # as angular templates (or regular AngularJS partials). They contain embedded
  # AngularJS variables and are useless when viewed by a search engine bot or
  # a browser without JavaScript.
  ngtplPath = parentPath + '/_ngtpl'
  app.locals.urls['articles.ngtpl.index'] = ngtplPath
  app.locals.urls['articles.ngtpl.create'] = ngtplPath + '/create'
  app.locals.urls['articles.ngtpl.view'] = ngtplPath + '/view'
  app.locals.urls['articles.ngtpl.edit'] = ngtplPath + '/edit'
  app.locals.urls['articles.ngtpl.delete'] = ngtplPath + '/delete'


  app.get app.locals.urls['articles.index'], (req, res, next) ->
    return artUtils.renderIndex app, req, res, next, false

  app.get app.locals.urls['articles.partials.index'], (req, res, next) ->
    return artUtils.renderIndex app, req, res, next, true

  # An AngularJS template that covers the page content area. This contains an
  # AngularJS variable that can be used to fill in the page content.
  app.get app.locals.urls['articles.ngtpl.index'], (req, res, next) ->
    return res.render 'articles/ngtpl/index',
      title: ''
      subTitle: ''
      section: 'articles'


  app.get app.locals.urls['articles.create'], (req, res, next) ->
    app.locals.hasPermission req, 'createArticles', (err, hasPermission) ->
      return next err if err
      if ! hasPermission
        err = new errors
          .ForbiddenError 'You are not authorized to create new articles.'
        return next err
      return artUtils.renderFullPage app,
        req, res, next, 'articles/create',
          title: 'Create New Article'
          subTitle: ''

  app.get app.locals.urls['articles.ngtpl.create'], (req, res, next) ->
    app.locals.hasPermission req, 'createArticles', (err, hasPermission) ->
      # TODO: Make a partial route for errors.
      return next err if err
      if hasPermission
        return artUtils.renderNgtpl app,
          req, res, next, 'articles/ngtpl/create',
          title: 'Create New Article'
          subTitle: ''
      err = new errors
        .ForbiddenError 'You are not authorized to create new articles.'
      return next err

  app.post app.locals.urls['articles.api.index'], (req, res, next) ->
    return artUtils.disableResCache res, (res) ->
      return input.handleCreate app, req, (err, article) ->
        if err
          if err instanceof errors.InputError
            output = {}
            output.error = true
            output.fieldErrors = err.fieldErrors
            return res.json output
          if err instanceof errors.ForbiddenError
            res.status err.status || 403
            return res.json false
          res.status err.status || 500
          return res.json error: true
        return res.json article


  # The regular article view page that can be used by a search engine bot or a
  # user-agent without JavaScript.
  app.get app.locals.urls['articles.view'], (req, res, next) ->
    artUtils.fetchReqArticle app, req, (err, article) ->
      return next err if err
      return next() if ! article
      return artUtils.renderFullPage app,
        req, res, next, 'articles/view',
          title: article.title
          subTitle: ''
          article: article

  # A full HTML rendering of the contents of the article view page. This can be
  # fetched and inserted by JavaScript.
  app.get app.locals.urls['articles.partials.view'], (req, res, next) ->
    return artUtils.fetchReqArticle app, req, (err, article) ->
      return next err if err
      return next if ! article
      return artUtils.renderPartial app,
        req, res, next, 'articles/partials/view',
        title: article.title
        subTitle: ''
        article: article

  # Returns JSON representation of the item.
  app.get app.locals.urls['articles.api.item'], (req, res, next) ->
    return artUtils.disableResCache res, (res) ->
      artUtils.fetchReqArticle app, req, (err, article) ->
        if err
          res.status err.status || 500
          return res.json error: true
        if ! article
          res.status 404
          return res.json error: true
        return res.json article

  # An AngularJS template that covers the page content area. This contains an
  # AngularJS variable that can be used to fill in the page content.
  app.get app.locals.urls['articles.ngtpl.view'], (req, res, next) ->
    return artUtils.renderNgtpl app,
      req, res, next, 'articles/ngtpl/view',
      title: ''
      subTitle: ''


  app.get app.locals.urls['articles.edit'], (req, res, next) ->
    artUtils.fetchReqArticle app, req, (err, article) ->
      return next err if err
      return next if ! article
      permissions.canEditArticle app, req, article, (err, canEdit) ->
        return next err if err
        if ! canEdit
          err = new errors
            .ForbiddenError 'You do not have permission to edit this article.'
          return next err
        return artUtils.renderFullPage app,
          req, res, next, 'articles/edit',
            title: 'Edit Article'
            subTitle: ''

  app.get app.locals.urls['articles.ngtpl.edit'], (req, res, next) ->
    return artUtils.renderNgtpl app,
      req, res, next, 'articles/ngtpl/edit',
      title: 'Edit Article'
      subTitle: ''

  app.put app.locals.urls['articles.api.item'], (req, res, next) ->
    return artUtils.disableResCache res, (res) ->
      return input.handleUpdate app, req, (err, article) ->
        if err
          if err instanceof errors.InputError
            output = {}
            output.error = true
            output.fieldErrors = err.fieldErrors
            return res.json output
          res.status err.status || 500
          if err instanceof errors.ForbiddenError
            res.status err.status || 403
          return res.json error: true
        return res.json article


  app.get app.locals.urls['articles.delete'], (req, res, next) ->
    artUtils.fetchReqArticle app, req, (err, article) ->
      return next err if err
      return next if ! article
      permissions.canEditArticle app, req, article, (err, canEdit) ->
        return next err if err
        if ! canEdit
          err = new errors
            .ForbiddenError 'You do not have permission to delete this article.'
          return next err
        return artUtils.renderFullPage app,
          req, res, next, 'articles/delete',
            title: 'Delete Article'
            subTitle: ''

  app.get app.locals.urls['articles.ngtpl.delete'], (req, res, next) ->
    return artUtils.renderNgtpl app,
      req, res, next, 'articles/ngtpl/delete',
      title: 'Delete Article'
      subTitle: ''

  app.delete app.locals.urls['articles.api.item'], (req, res, next) ->
    return artUtils.disableResCache res, (res) ->
      return input.handleDelete app, req, (err) ->
        if err
          res.status err.status || 500
          if err instanceof errors.ForbiddenError
            res.status err.status || 403
          return res.json error: true
        return res.json true


module.exports =
  assign: assign
