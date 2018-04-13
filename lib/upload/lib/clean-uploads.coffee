# npm packages

fs = require 'fs.extra'
async = require 'async'


existsFn = fs.exists || path.exists
existsSync = fs.existsSync || path.existsSync


ensureDeleted = (path, cb)->
  existsFn path, (exists)->
    if exists
      fs.unlink path, (err)->
        cb err
    else
      cb null


#
# Go through the req.files array multer will create and make sure every temp
# file has been deleted.
#
cleanUploads = (callNext = false)->
  return (req, res, next)->
    if !(typeof req.files == 'object')
      next() if callNext
    else
      # Asynchronously ensure each file is deleted.
      asyncTasks = []
      # As noted in mongoose-file-attachments, we need to iterate using
      # something like `forEach` to make sure the iterating value we are using
      # is a unique variable. If we use a `for` loop, all async tasks will end
      # up with the value of the last item in the loop. I get the `req.files`
      # object's keys into an array with `Object.keys` function (only in IE 9
      # or later) and use that array's `forEach` to iterate.
      # If I knew how to guarantee a string value was copied in JavaScript I
      # wouldn't need `forEach`.
      keys = Object.keys req.files
      keys.forEach (key)->
        # Make sure each file has been deleted.
        asyncTasks.push (cb)->
          ensureDeleted req.files[key].path, cb
      async.parallel asyncTasks, ()->
        next() if callNext


module.exports = exports =
  cleanUploads:  cleanUploads
  ensureDeleted: ensureDeleted
