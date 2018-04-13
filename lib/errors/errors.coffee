util = require 'util'

# Custom Error classes
#
# Code here based on http://dustinsenos.com/articles/customErrorsInNode

AbstractError = (msg, constr) ->
  Error.captureStackTrace @, constr || @
  @message = msg || 'Error'
  return
util.inherits AbstractError, Error
AbstractError.prototype.name = 'Abstract Error'


ForbiddenError = (msg) ->
  ForbiddenError.super_.call @, msg, @constructor
  @status = 403
  return
util.inherits ForbiddenError, AbstractError
ForbiddenError.prototype.name = 'Forbidden Error'


NotFoundError = (msg) ->
  NotFoundError.super_.call @, msg, @constructor
  @status = 404
  return
util.inherits NotFoundError, AbstractError
NotFoundError.prototype.name = 'Not Found Error'


InputError = (msg, errors) ->
  InputError.super_.call @, msg, @constructor
  if (typeof errors == 'undefined')
    @fieldErrors = {}
  else
    @fieldErrors = errors
  return
util.inherits InputError, AbstractError
InputError.prototype.name = 'Input Error'


module.exports = {
  ForbiddenError: ForbiddenError
  InputError: InputError
}
