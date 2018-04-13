#
# Model for user roles
#
# Stores assigned permissions.

# Node Packages
mongoose = require('mongoose')


roleSchema = mongoose.Schema
  name:
    type: String
    required: true
    index:
      unique: true
  description: String
  permissions:
    type: [String]


roleSchema.methods.hasPermission = (permission, cb) ->
  if (this.permissions.indexOf permission) != -1
    return cb(null, true)
  return cb(null, false)


Role = mongoose.model('Role', roleSchema)


module.exports = Role
