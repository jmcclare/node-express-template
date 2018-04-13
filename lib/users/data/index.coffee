Role = require './role'
User = require './user'


# Use this to create some sample data.
createSampleData = ->
  new Role(
    name: 'everyone'
    description: 'Default role with permissions that all visitors are granted.'
    permissions: ['viewUsersList']
  ).save (err, role) ->
    if err
      console.log err
    console.log 'Saved role ' + role.name

  new Role(
    name: 'user'
    description: 'Default role with permissions that all logged-in users are granted.'
    permissions: ['viewUsersList']
  ).save (err, role) ->
    if err
      console.log err
    console.log 'Saved role ' + role.name

  new Role(
    name: 'editor'
    description: 'Edits and published site content.'
    permissions: ['createArticles', 'editArticles', 'publishArticles']
  ).save (err, role1) ->
    if err
      console.log 'Error saving role: ' + err
    console.log 'Saved role ' + role1.name
    new Role(
      name: 'publisher'
      description: 'Site administrator with full permissions.'
      permissions: ['createArticles', 'publishArticles', 'viewUsersList']
    ).save (err, role2) ->
      if err
        console.log 'Error saving role: ' + err
      console.log 'Saved role ' + role2.name
      new User(
        username: 'james'
        password: 'supersecret'
        fullName: 'James Han'
        administrator: true
      ).save (err, user) ->
          if err
            console.log 'Error saving user: ' + err
          console.log 'Saved user'
          # Fetch the data for the ObjectIDs in the roles array.
          user.populate 'roles', (err, user) ->
            console.log user
      new User(
        username: 'ryan'
        password: 'supersecret'
        fullName: 'Ryan Eldridge'
      ).save (err, user) ->
          if err
            console.log 'Error saving user: ' + err
          console.log 'Saved user'
      new User(
        username: 'shelly'
        password: 'supersecret'
        fullName: 'Shelly Nguyen'
        administrator: false
        roles: [role1._id, role2._id]
      ).save (err, user) ->
          if err
            console.log 'Error saving user: ' + err
          console.log 'Saved user'
          # Fetch the data for the ObjectIDs in the roles array as we load the
          # object.
          User.findOne({username: 'shelly'})
            .populate('roles')
            .exec (err, user) ->
              if err
                console.log err
              else
                console.log user

# Uncomment this to create the sample data when the server is started.
#createSampleData()


module.exports =
  User: User
  Role: Role
  createSampleData: createSampleData
