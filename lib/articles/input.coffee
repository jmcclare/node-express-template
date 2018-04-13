# Functions for checking and operating on user input.

errors = require('errors').errors

articleErrors = require './errors'
Article = require('articles/data').Article
fetchReqArticle = require('./routes').fetchReqArticle
routes = require './routes'
permissions = require './permissions'
artUtil = require './utilities'


handleCreate = (app, req, cb) ->
  checkCreateInput req, (err) ->
    # TODO: refactor these with the `return cb err if err` pattern. Remove
    # else's.
    if err
      cb err
    else
      checkCreatePermissions app, req, (err) ->
        if err
          cb err
        else
          saveNewArticle req, (err, article) ->
            return artUtil.populateArticle app, req, article, (err, article) ->
              cb err, article


handleUpdate = (app, req, cb) ->
  return artUtil.fetchReqArticle app, req, (err, article) ->
    return cb err if err
    if ! article
      err = new errors
        .NotFoundError 'The article you are trying to edit could not be found.'
      return cb err
    return checkUpdateInput req, (err) ->
      return cb err if err
      return checkUpdatePermissions app, req, article, (err) ->
        return cb err if err
        return updateArticle req, article, (err, article) ->
          # Re-populate the updated article to update the extra data.
          return artUtil.populateArticle app, req, article, (err, article) ->
            return cb err, article


handleDelete = (app, req, cb) ->
  artUtil.fetchReqArticle app, req, (err, article) ->
    return cb err if err
    if ! article
      err = new errors
        .NotFoundError 'The article you are trying to delete could not be found.'
      return cb err
    checkDeletePermissions app, req, article, (err) ->
      return cb err if err
      deleteArticle article, (err) ->
        return cb err


checkGeneralInput = (req, cb) ->
  fieldErrors = {}
  foundErrors = false

  if req.body.title == '' || typeof req.body.title == 'undefined'
    fieldErrors.title = 'The title cannot be blank.'
    foundErrors = true
  if req.body.body == '' || typeof req.body.body == 'undefined'
    fieldErrors.body = 'The body cannot be blank.'
    foundErrors = true

  if foundErrors
    err = new errors
      .InputError "Some fields were not filled in correctly.", fieldErrors
    return cb err
  return cb null

checkCreateInput = (req, cb) ->
  fieldErrors = {}
  foundErrors = false

  checkGeneralInput req, (err) ->
    if err
      if err instanceof errors.InputError
        foundErrors = true
        for key of err.fieldErrors
          fieldErrors[key] = err.fieldErrors[key]
      else
        return cb err

    # Check any create-specific conditions here

    if foundErrors
      err = new errors
        .InputError "Some fields were not filled in correctly.", fieldErrors
      return cb err
    return cb null

checkUpdateInput = (req, cb) ->
  fieldErrors = {}
  foundErrors = false

  checkGeneralInput req, (err) ->
    if err
      if err instanceof errors.InputError
        foundErrors = true
        for key of err.fieldErrors
          fieldErrors[key] = err.fieldErrors[key]
      else
        return cb err

    # Check any update-specific conditions here

    if foundErrors
      err = new errors
        .InputError "Some fields were not filled in correctly.", fieldErrors
      return cb err
    return cb null


checkCreatePermissions = (app, req, cb) ->
  # TODO:
  # * check for publishArticles permission
  app.locals.hasPermission req, 'createArticles', (err, hasPermission) ->
    return cb err if err
    if ! hasPermission
      fbnErr = new errors
        .ForbiddenError 'This requester does not have permission to create articles.'
      return cb fbnErr
    return cb null

checkUpdatePermissions = (app, req, article, cb) ->
  # TODO:
  # * check for publishArticles permission
  permissions.canEditArticle app, req, article, (err, canEdit) ->
    return cb err if err
    if ! canEdit
      fbnErr = new errors
        .ForbiddenError 'You do not have permission to edit this article.'
      return cb fbnErr
    return cb null

checkDeletePermissions = (app, req, article, cb) ->
  permissions.canEditArticle app, req, article, (err, canEdit) ->
    return cb err if err
    if ! canEdit
      fbnErr = new errors
        .ForbiddenError 'You do not have permission to delete this article.'
      return cb fbnErr
    return cb null


#
# Convert the user input into a new article and save it.
#
# callback takes err, if needed, and saved article object.
#
saveNewArticle = (req, cb) ->
  if req.body.pubTime
    pubTime = new Date req.body.pubTime
  else
    pubTime = null
  preppedArticle =
    title: req.body.title
    author: req.user
    description: req.body.description
    summary: req.body.summary
    body: req.body.body
    bodyFormat: req.body.bodyFormat
    pubTime: pubTime
  new Article(preppedArticle).save (err, article) ->
    return cb err, null if err
    return cb null, article

updateArticle = (req, article, cb) ->
  if req.body.pubTime
    article.pubTime = new Date req.body.pubTime
  else
    article.pubTime = null
  article.title = req.body.title
  article.description = req.body.description
  article.summary = req.body.summary
  article.body = req.body.body
  article.bodyFormat = req.body.bodyFormat
  article.save (err, article) ->
    return cb err, null if err
    return cb null, article

deleteArticle = (article, cb) ->
  article.remove (err) ->
    return cb err



module.exports = exports =
  handleCreate: handleCreate
  handleUpdate: handleUpdate
  handleDelete: handleDelete
