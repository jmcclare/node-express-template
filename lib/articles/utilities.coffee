Article = require('articles/data').Article
permissions = require './permissions'


#
# Fetches article based on the request slug param.
# Populates the article author.
#
fetchReqArticle = (app, req, cb) ->
  Article.findOne slug: req.params.slug, (err, article) ->
    return cb err if err
    return cb() if ! article
    # TODO: check permissions for unpublished articles.
    article.populate 'author', (err, article) ->
      return cb err if err
      return populateArticle app, req, article, cb


#
# Populates article fields that are not populated by the default, fast article
# loading.
#
# Params:
#   * app - instance of your site's Express app with urls and permissions added
#   * req - current request object
#   * article - loaded article object
#   * cb - callback function that takes err, article
#
# Populates:
#   * author
#   * path - path of the article's view page
#   * editPath - path of the article's edit page
#   * deletePath - path of the article's delete page
#
populateArticle = (app, req, article, cb) ->
    article.populate 'author', (err, article) ->
      return cb err if err

      # Set the article's paths.
      #
      # I still don't know much about JavaScript objects.
      # Setting an object's property with a simple assignment statement works
      # when passing the object around within the Node.js program. When
      # res.json converts it, the property will be ignored.
      # Setting an object's property with `setValue` makes it unavailable with
      # normal property references (maybe getValue would work), but it will
      # show up when res.json converts it and when you use console.log to
      # inspect it within Node.js.
      # To ensure I can use them in both cases, I set these properties both
      # ways.
      article.path = app.locals.url 'articles.view', slug: article.slug
      article.setValue 'path', article.path
      if req.user
        # Populate any appropriate editing paths.
        return permissions.canEditArticle app, req, article, (err, canEdit) ->
          return cb err if err
          if canEdit
            article.editPath =
              app.locals.url 'articles.edit', slug: article.slug
            article.setValue 'editPath', article.editPath
            article.deletePath =
              app.locals.url 'articles.delete', slug: article.slug
            article.setValue 'deletePath', article.deletePath
          return cb null, article

      return cb null, article


#
# Sets response headers that tell user agents like Internet Explorer to not
# cache the response and fetch it again the next time they are told to. IE very
# aggressively caches XMLHTTPRequest responses. This prevents that.
#
disableResCache = (res, cb) ->
  res.set
    "Cache-Control": "no-cache"
    "Pragma": "no-cache"
    "Expires": "-1"
  return cb res


#
# Gets the value of ngApp for the given request.
#
# Currently, it disables it for non-logged in users. In the future, it could
# check the user agent string and disable it for certain browsers.
#
# Params:
#   * req - request object
#   * cb - callback function that takes:
#     * err - any error encountered, or null
#     * ngApp - string, value to use for ngApp, possibly an empty string.
#
getNgApp = (req, cb) ->
  if req.user
    return cb null, 'articles'
  return cb null, ''


#
# Get a list of all unpublished articles.
#
# Params:
#   * req - the current request object
#   * cb - allback function. Takes;
#     * err - error, or null if none encountered
#     * articles - list of article objects
#
getUnpubArticles = (req, cb) ->
  # Apparently, the $where funciton is innefficient, but it worked.
  #Article.find()
    #.$where('this.pubTime == null || this.pubTime > ' + Date.now())
  Article.find(
      {
        $or:
          [
            { pubTime: null },
            { pubTime: { $gt: Date.now() } }
          ]
      }
    )
    .exec (err, articles) ->
      return cb err if err
      return cb null, articles


#
# Renders any HTML producing view (full, partial, ngtpl) after it's unique
# variables have been defined.
# Defines variables common to all HTML views.
#
# Parameters:
#   * app - Express app object
#   * req - request object
#   * res - response object
#   * next - function to call upon error, resource not found, etc.
#   * view - name of view (template) to render
#   * vars - dict - optional route-specific variables.
#
renderCommon = (app, req, res, next, view, vars) ->
  vars = {} if typeof vars == 'undefined' || ! vars
  vars.section = 'articles'
  return app.locals.hasPermission req,
    'createArticles', (err, hasPermission) ->
      return next err if err
      if hasPermission
        # only users who can create articles have any reason to see the
        # unpublished ones.
        return getUnpubArticles req, (err, unpubArticles) ->
          return next err if err
          vars.unpubArticles = unpubArticles
          return res.render view, vars
      # define the property to prevent view errors.
      vars.unpubArticles = null
      return res.render view, vars


#
# Renders full page views, ie. views that are not a partial, a JSON response,
# etc.
# Gathers template variables needed by all full page views.
#
# Parameters:
#   * app - Express app object
#   * req - request object
#   * res - response object
#   * next - function to call upon error, resource not found, etc.
#   * view - name of view (template) to render
#   * vars - dict - optional route-specific variables.
#
renderFullPage = (app, req, res, next, view, vars) ->
  vars = {} if typeof vars == 'undefined' || ! vars
  vars.baseURL = app.locals.urls['articles.index'] + '/'
  return getNgApp req, (err, ngApp) ->
    return next err if err
    vars.ngApp = ngApp
    return renderCommon app, req, res, next, view, vars


#
# Renders partial page elements.
# Gathers template variables needed by all full page views.
#
# Parameters:
#   * app - Express app object
#   * req - request object
#   * res - response object
#   * next - function to call upon error, resource not found, etc.
#   * view - name of view (template) to render
#   * vars - dict - optional route-specific variables.
#
renderPartial = (app, req, res, next, view, vars) ->
  vars = {} if typeof vars == 'undefined' || ! vars
  return disableResCache res, (res) ->
    return renderCommon app, req, res, next, view, vars


#
# Renders Angular template (ngtpl) views.
# Gathers template variables needed by all full page views.
# This is the same as rendering a partial, only we don't disable response
# caching.
#
# Parameters:
#   * app - Express app object
#   * req - request object
#   * res - response object
#   * next - function to call upon error, resource not found, etc.
#   * view - name of view (template) to render
#   * vars - dict - optional route-specific variables.
#
renderNgtpl = (app, req, res, next, view, vars) ->
  vars = {} if typeof vars == 'undefined' || ! vars
  return renderCommon app, req, res, next, view, vars


#
# Renders the index page and the index partial.
#
# Parameters:
#   * app - Express app object
#   * req - request object
#   * res - response object
#   * next - function to call upon error, resource not found, etc.
#   * partial - boolean - whether or not you are rendering the partial (content
#   area only), or the full page.
#
renderIndex = (app, req, res, next, partial = false) ->
  if partial
    template = 'articles/partials/index'
    renderFunc = renderPartial
  else
    template = 'articles/index'
    renderFunc = renderFullPage

  queryFilter = pubTime: { $lt: Date.now() }
  query = Article.find queryFilter

  return query.count (err, count) ->
    itemsPerPage = app.locals.articlesApp.itemsPerPage
    totalPages = parseInt(count / itemsPerPage, 10)
    totalPages++ if count % itemsPerPage > 0

    dispPage = if req.query.page then parseInt(req.query.page, 10) else 1
    # Pass this on for a 404 error if requesting a non-existent page.
    return next() if isNaN dispPage
    return next() if dispPage < 1 || dispPage != 1 && dispPage > totalPages

    # We subtract 1 here so that the page numbers in the URL can be 1-based
    # instead of 0-based like a programming language.
    page = dispPage - 1

    trailingSlash = if partial then '/' else ''

    if dispPage > 1
      prevPageNumber = dispPage - 1
      prevURL = app.locals.url('articles.index') + trailingSlash + '?page=' + prevPageNumber
    else prevURL = ''

    if dispPage < totalPages
      nextPageNumber = dispPage + 1
      nextURL = app.locals.url('articles.index') + trailingSlash + '?page=' + nextPageNumber
    else nextURL = ''

    query = Article.find(queryFilter)
      .sort('-pubTime')
      .limit(itemsPerPage).skip(page * itemsPerPage)
      .populate('author')

    return query.exec (err, articles) ->
        if err
          # Pass to the next route / middleware; probably the catch-all 500
          # handler.
          return next err
        # Check permissions to see if we should show the "Create New Article"
        # link.
        app.locals.hasPermission req, 'createArticles', (err, hasPermission) ->
          return next err if err
          return renderFunc app,
            req, res, next, template,
            title: 'Articles'
            subTitle: 'Latest Articles'
            articles: articles
            canCreate: hasPermission
            prevURL: prevURL
            nextURL: nextURL

  #return Article.find(
      #pubTime: { $lt: Date.now() }
    #)
    #.sort('-pubTime')
    #.limit(itemsPerPage).skip(page * itemsPerPage)
    #.populate('author')
    #.exec (err, articles) ->
      #if err
        ## Pass to the next route / middleware; probably the catch-all 500
        ## handler.
        #return next err
      ## Check permissions to see if we should show the "Create New Article"
      ## link.
      #app.locals.hasPermission req, 'createArticles', (err, hasPermission) ->
        #return next err if err
        #return renderFunc app,
          #req, res, next, template,
          #title: 'Articles'
          #subTitle: 'Latest Articles'
          #articles: articles
          #canCreate: hasPermission
          #prevURL: prevURL
          #nextURL: nextURL


module.exports =
  fetchReqArticle: fetchReqArticle
  populateArticle: populateArticle
  disableResCache: disableResCache
  getNgApp: getNgApp
  getUnpubArticles: getUnpubArticles
  renderFullPage: renderFullPage
  renderPartial: renderPartial
  renderNgtpl: renderNgtpl
  renderIndex: renderIndex
