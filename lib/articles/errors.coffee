util = require 'util'


AbstractError = (msg, constr) ->
  Error.captureStackTrace @, constr || @
  @message = msg || 'Error'
  return
util.inherits AbstractError, Error
AbstractError.prototype.name = 'Abstract Error'


#
# An example error class.
# InputError was moved to the errors module.
#
#InputError = (msg, errors) ->
  #InputError.super_.call @, msg, @constructor
  #if (typeof errors == 'undefined')
    #@fieldErrors = {}
  #else
    #@fieldErrors = errors
  #return
#util.inherits InputError, AbstractError
#InputError.prototype.name = 'Input Error'


module.exports = {
  #InputError: InputError
}
