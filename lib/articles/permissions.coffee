permissions =
  createArticles:
    group: 'articles'
    description: 'create new articles'
  publishArticles:
    group: 'articles'
    description: 'publish articles'
  editArticles:
    group: 'articles'
    description: "edit other users' articles"


#
# Determines if a request has permission to edit an article.
#
# Parameters:
#   * app - current instance of the Express app. Must have locals.hasPermission
#   * req - request object
#   * article - article object. SHould already have it's author populated.
#   * cb - callback function. Takes:
#     * Error (if any)
#     * boolean - the result
#
canEditArticle = (app, req, article, cb) ->
  # If this user is the article author, she can edit the article.
  if ! req.user || ! article.author
    return cb null, false
  if article.author.username == req.user.username
    return cb null, true
  # A user with the editArticles permission can edit any article.
  app.locals.hasPermission req, 'editArticles', (err, hasPermission) ->
    return cb err if err
    return cb null, hasPermission


module.exports =
  permissions: permissions
  canEditArticle: canEditArticle 
