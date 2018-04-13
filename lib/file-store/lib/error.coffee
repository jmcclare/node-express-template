# Custom Error classes
#
# Code here based on http://dustinsenos.com/articles/customErrorsInNode
#
# NOTE: I should probably update this to use CoffeeScript class syntax.


# Node libraries

util = require 'util'


AbstractError = (msg, constr) ->
  Error.captureStackTrace @, constr || @
  @message = msg || 'Error'
  return
util.inherits AbstractError, Error
AbstractError.prototype.name = 'AbstractError'


FileMissingError = (msg) ->
  FileMissingError.super_.call @, msg, @constructor
  @message = msg || 'File does not exist.'
  return
util.inherits FileMissingError, AbstractError
FileMissingError.prototype.name = 'FileMissingError'


module.exports =
  FileMissingError: FileMissingError
