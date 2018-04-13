
#
# Module dependencies.
#

express = require 'express'
http = require 'http'
path = require 'path'
stylus = require 'stylus'
nib = require 'nib'

app = express()
app.root = __dirname
app.lib = path.join __dirname, 'lib'

# Add the configuration
require('./config')(app)

app.set 'port', process.env.PORT || 3000
http.createServer(app).listen app.get('port'), () ->
  console.log "Express server listening on port " + app.get 'port'
