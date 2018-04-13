#
# Model for stored user objects.
#

# Node Packages
mongoose = require('mongoose')
ObjectId = mongoose.Schema.Types.ObjectId
bcrypt = require 'bcrypt'

# Local Packages
Role = require './role'

SALT_WORK_FACTOR = 10


userSchema = mongoose.Schema
  username:
    type: String
    required: true
    index:
      unique: true
  password:
    type: String
    required: true
  fullName: String
  administrator:
    type: Boolean
    default: false
  roles: [{ type: ObjectId, ref: 'Role' }]


userSchema.pre 'save', (next) ->
  user = this

  # only hash the password if it has been modified (or is new)
  if !user.isModified 'password'
    return next()

  # generate a salt
  bcrypt.genSalt SALT_WORK_FACTOR, (err, salt) ->
    if err
      return next(err)

    # hash the password along with our new salt
    bcrypt.hash user.password, salt, (err, hash) ->
      if err
        return next(err)

      # override the cleartext password with the hashed one
      user.password = hash
      next()


userSchema.methods.comparePassword = (candidatePassword, cb) ->
  bcrypt.compare candidatePassword, this.password, (err, isMatch) ->
    if (err)
      return cb(err)
    cb(null, isMatch)


#
# hasPermission
#
# permission - string - name of the permission to check
# cb - function that takes two parameters:
#   err - any unhandled error encountered by hasPermission, or null
#   hasPermission - boolean - whether or not the user has the permission
userSchema.methods.hasPermission = (permission, cb) ->
  user = this

  # Factor this logic out to avoid repeating it below.
  checkUserRoles = ->
    user.populate 'roles', (err, user) ->
      if err
        # Grant no permissions if an error occurs.
        return cb(err, false)
      perms = []
      for role in user.roles
        perms = perms.concat role.permissions
      if (perms.indexOf permission) != -1
        return cb(null, true)
      return cb(null, false)

  # Administrators have all available permissions.
  if user.administrator
    return cb(null, true)

  # See if 'users' role has this permission.
  # We grant all logged-in users the permissions of the 'users' role, if it
  # exists.
  Role.findOne name: 'users', (err, role) ->
    if err
      return cb err, false
    if role
      role.hasPermission permission, (err, hasPermission) ->
        if err
          return cb err, false
        if hasPermission
          return cb null, true
        return checkUserRoles()
    else
      return checkUserRoles()


User = mongoose.model('User', userSchema)


module.exports = User
