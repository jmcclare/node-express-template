
# Sample Local Settings

# This is set to act the same as the production settings unless NODE_ENV is set
# to development. If you want to make a local config for a development
# environment, you can change the logic below to default to development
# settings.

errors = require 'errors'
mongoose = require 'mongoose'


regular = (app) ->

  # Initialize MongoDB
  # The commented lines are just some sample trace output.
  # Remove this section if you are not using mongoose.
  # TODO: Set your DB server's connection string and options for the current
  # site. See the mongoose docs for more.
  # TODO: have this use the mongodb_host and mongodb_db environment variables
  # if defined.
  mongoose.connect('mongodb://localhost/node-express-production')
  #console.log 'MongoDB connection attempt started...'
  db = mongoose.connection
  db.on 'error', console.error.bind console, 'connection error:'
  # Not necessary, but useful.
  db.once 'open', () ->
    console.log 'MongoDB connection opened.'

  # TODO: Set these to addresses you can use on your live server.
  # `from` should be any address at a domain that resolves to the server's IP
  # address.
  # `to` is the comma-separated list of addresses you want messages sent with
  # the site contact form to go to. Examples:
  #   'name@example2.com'
  #   'name@example1.com, anothername@example2.com'
  app.set 'contactMailOptions',
    from: 'no-reply@sitedomain.com' # the domain of this address should point to the server that will send the mail.
    to: 'recipient1@mailhost1.com, recipient2@mailhost2.com'
    # For a local development site, these settings should do:
    #from: 'express-site@localhost'
    #to: 'root@localhost'
    # Change 'root' to your username if root mail is not redirected to you.
    #
    # You can also set a 'subject' for the messages here. Otherwise, a
    # default one will be used.


  # TODO: Set the preferred Google Analytics account code for this site's
  # domain.
  app.locals.gaAccount = 'UA-XXXXXXXX-X'

  # Optionally, set a preferred account code for each domain here.
  app.use (req, res, next) ->
    #if req.headers.host == 'example.com'
      #res.locals.gaAccount = 'UA-XXXXXXXX-1'
    #if req.headers.host == 'example2.com'
      #res.locals.gaAccount = 'UA-XXXXXXXX-2'

    next()


error = (app) ->
  return


module.exports =
  regular: regular
  error: error
