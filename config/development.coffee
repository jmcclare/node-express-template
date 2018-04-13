express = require 'express'
morgan = require 'morgan'
errorHandler = require 'errorhandler'


regular = (app) ->
  # Express 4.0 does not have a logger built in. morgan is the recommended one.
  app.use morgan 'dev'


error = (app) ->
  #app.use require("express").errorHandler
  # As of Express 4.0, errorhandler comes separately.
  app.use errorHandler
    dumpExceptions: true
    showStack: true


module.exports =
  regular: regular
  error: error
