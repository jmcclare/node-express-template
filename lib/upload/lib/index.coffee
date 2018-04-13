setUpTmp = require './set-up-tmp'
cleanUploadsModule = require './clean-uploads'

module.exports = exports =
  setUpTmp:      setUpTmp
  cleanUploads:  cleanUploadsModule.cleanUploads
  ensureDeleted: cleanUploadsModule.ensureDeleted
