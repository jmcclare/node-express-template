# 
# Module dependencies.
# 

# local libraries
urls = require 'urls'
contact = require 'contact'
users = require 'users'
auth = require 'auth'
articles = require 'articles'

# For testing
posts = require 'posts'


module.exports = (app) ->
  if ! app.locals.urls
    urls.addHelpers app

  #
  # GET home page.
  # 
  app.get app.locals.urls['home'], (req, res, next) ->
    res.render 'home',
      title: 'Node Express Sample Template'
      section: 'site-root'

  contact.routes.assign app, '/contact'
  users.routes.assign app, '/users'
  auth.routes.assign app
  articles.routes.assign app

  # For testing
  posts.routes.assign app
