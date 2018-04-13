# 
# Module dependencies.
# 

# Standard modules
os   = require 'os'
path = require 'path'

# npm packages
fs   = require 'fs.extra'


existsFn   = fs.exists || path.exists
existsSync = fs.existsSync || path.existsSync


#
# makes sure the uploads dir in /tmp exists.
#
# This runs synchronously, but it's meant to be run once during app startup, so
# this shouldn't be a big problem.
#
setUpTmp = (app)->
  if app.get 'upTmp'
    upTmp = app.get 'upTmp'
  else
    upTmp = path.join os.tmpDir(), 'node-upload'
    app.set 'upTmp', upTmp
  existsFn upTmp, (exists)->
    if ! exists
      # Clear the process' umask so that the mode we use below isn't masked.
      oldMask = process.umask 0o000
      fs.mkdirp upTmp, 0o775, (err, made)->
        # Reset the process' umask
        process.umask oldMask
        if err
          console.log err


module.exports = exports = setUpTmp
