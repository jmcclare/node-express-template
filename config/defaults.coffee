#
# Safe defaults for variables used by all templates
#

# Standard libraries
os   = require 'os'
path = require 'path'


module.exports = (app) ->

  # 
  # Add safe defaults for variables used by all templates.
  # 
  # Some of these variables should still be defined by each route, but this
  # will prevent errors simply from forgetting them.
  # 
  # These must simply be set before any routes are added.
  # 
  app.use (req, res, next) ->
    # Add the req object to res.locals here so that all views have access to it.
    res.locals.req = req

    res.locals.title = ''
    res.locals.subTitle = ''
    res.locals.section = ''
    res.locals.description = ''
    res.locals.author = ''
    # If filled in, placed in a `href` of the `base` tag in the `head` tag.
    res.locals.baseURL = ''
    # If filled in, used as the value of the `ng-app` property of the `html` tag.
    # This sets the name of an AngularJS app that controls the entire page. You
    # must also declare a baseURL so that links to pages outside of that app
    # still work.
    res.locals.ngApp = ''

    next()
