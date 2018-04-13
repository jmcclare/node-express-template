express = require 'express'
morgan = require 'morgan'

errMw = require('errors').middleware


regular = (app) ->
  app.use (err, req, res, next) ->
    console.log err.stack
  # Express 4.0 does not have a logger built in. morgan is the recommended one.
  app.use morgan 'combined'


error = (app) ->
  app.use errMw.serverError


module.exports =
  regular: regular
  error: error
