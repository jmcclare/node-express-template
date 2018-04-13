# Custom Error classes
#
# Code here based on http://dustinsenos.com/articles/customErrorsInNode
#
# NOTE: I should probably update this to use CoffeeScript class syntax.


# Node libraries

util = require 'util'


# Local libraries

fileStore = require 'file-store'


module.exports =
  FileMissingError: fileStore.FileMissingError
