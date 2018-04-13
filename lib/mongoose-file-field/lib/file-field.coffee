
# Standard packages

debug = require('debug')('mongoose-file-field')


# Node packages

async = require 'async'


# local packages

fileStore = require 'file-store'
tools = require 'tools'


plugin = (schema, options)->
  opType = typeof options
  if opType != 'undefined' && opType != 'object'
    throw new TypeError 'Invalid options supplied. Pass an object or omit options.'

  if typeof options.fieldName == 'undefined' || ! options.fieldName
    fieldName = 'file'
  else
    fieldName = options.fieldName

  # Make sure we have fileStore Options to work with, even if they're blank.
  if options.fileStoreOptions
    fileStoreOptions = options.fileStoreOptions
  else
    fileStoreOptions = {}
  debug 'fileStoreOptions: ', fileStoreOptions

  # Make sure no field with the same name exists before adding it.
  if schema.path fieldName
    throw new Error 'A field named ' + fieldName + ' already exists in this schema.'

  schemaAdditions = {}
  schemaAdditions[fieldName] = { type: {}, default: {}, fileStoreOptions: fileStoreOptions }
  schema.add schemaAdditions

  # Add an array field to track the file fields assigned to this schema.
  debug 'schema.path _fileFields', schema.path '_fileFields'
  if ! schema.path '_fileFields'
    schema.add
      _fileFields: { type: {}, default: {} }


  schema.methods.updateff = (fieldName, attachmentInfo, cb)->
    debug 'in updateff'
    modelInstance = this

    if ! fieldName
      return cb new Error 'no valid fieldName specified'
    if typeof fieldName != 'string'
      throw new TypeError 'fieldName must be a string.'
    if ! schema.path fieldName
      return cb new Error 'no field matching fieldName'
    if (!attachmentInfo || typeof(attachmentInfo) != 'object')
      return cb new Error 'attachmentInfo is not valid'
    if (typeof(attachmentInfo.path) != 'string')
      return cb new Error 'attachmentInfo has no valid path'

    fieldSchema = schema.path fieldName

    # Make sure we have fileStore Options to work with, even if they're blank.
    if fieldSchema.options.fileStoreOptions
      fileStoreOptions = fieldSchema.options.fileStoreOptions
    else
      fileStoreOptions = {}
    debug 'fileStoreOptions: ', fileStoreOptions

    return tools.clone fileStoreOptions, (err, currentOptions) ->
      if err
        debug 'clone error: ', err
        return cb err
      debug 'cloned successfully'

      if attachmentInfo.originalname
        currentOptions.originalFileName = attachmentInfo.originalname

      # multer has its own method of filtering the filename. The result of that
      # gets stored in attachmentInfo.name. I don't use that because it gets
      # set to the random temp filename if you don't give multer a function to
      # filter the original with.
      #
      # storedFileName is the name you want to store the file under. If this is
      # not filled in, we will use whatever FileStore defaults to –see
      # FileStore.store().
      if attachmentInfo.storedFileName
        currentOptions.fileName = attachmentInfo.storedFileName

      # If we don't specify a fileName or originalFileName FileStore will use
      # the name of the file on disk that is being stored.
      
      # This will also be inferred from other options or the name of the file
      # on disk if not provided.
      if attachmentInfo.displayName
        currentOptions.name = attachmentInfo.displayName

      # This will not be inferred from other data, but it's optional. It
      # defaults to an empty string.
      if attachmentInfo.description
        currentOptions.description = attachmentInfo.description

      storeStage = ()->
        debug 'storing file...'
        return fileStore.store attachmentInfo.path, currentOptions, (err, file) ->
          debug 'in fileStore.store callback'
          return cb err if err
          debug 'file object: ', file
          modelInstance[fieldName] = file
          # Mark the field as filled for the pre-remove hook.
          modelInstance._fileFields[fieldName] = true
          modelInstance.markModified '_fileFields'
          return cb null, modelInstance

      if typeof modelInstance[fieldName] == 'object' && typeof modelInstance[fieldName].fileName == 'string'
        # There is an existing file stored for this field. Delete it before
        # storing the new one.
        debug 'deleting existing file...'
        return fileStore.delete modelInstance[fieldName], fileStoreOptions, (err)->
          return cb err if err
          modelInstance[fieldName] = {}
          # Temporarily mark the field as filled for the pre-remove hook.
          modelInstance._fileFields[fieldName] = false
          modelInstance.markModified '_fileFields'
          return storeStage()
      else
        return storeStage()


  schema.methods.ffurl = (fieldName)->
    debug 'in ffurl'
    modelInstance = this
    #debug 'modelInstance: ', modelInstance

    if ! fieldName
      return cb new Error 'no valid fieldName specified'
    if typeof fieldName != 'string'
      throw new TypeError 'fieldName must be a string.'
    #debug 'schema.path fieldName: ', schema.path fieldName
    if ! schema.path fieldName
      return cb new Error 'no field matching fieldName'

    #debug 'modelInstance[fieldName]: ', modelInstance[fieldName]

    if typeof modelInstance[fieldName] == 'object' && typeof modelInstance[fieldName].fileName == 'string'
      # We've passed a basic check that there is a file object stored in modelinstance.fieldName
      debug 'returning file URL...'
      return fileStore.pubPath modelInstance[fieldName], options
    else
      # No file currently stored. Return blank.
      debug 'returning blank...'
      return ''


  schema.methods.clearff = (fieldName, cb)->
    debug 'in ffurl'
    instance = this

    if ! fieldName
      return cb new Error 'no valid fieldName specified'
    if typeof fieldName != 'string'
      throw new TypeError 'fieldName must be a string.'
    debug 'schema.path fieldName: ', schema.path fieldName
    if ! schema.path fieldName
      return cb new Error 'no field matching fieldName'

    fieldSchema = schema.path fieldName

    if typeof instance[fieldName] == 'object' && typeof instance[fieldName].fileName == 'string'
      # We've passed a basic check that there is a file object stored in modelinstance.fieldName

      debug 'deleting file...'
      debug 'file: ', instance[fieldName]
      fileStore.delete instance[fieldName], fieldSchema.options.fileStoreOptions, (err)->
        debug 'in delete callback'
        debug err if err
        return cb err if err
        instance[fieldName] = {}
        # Mark the field as cleared for the pre-remove hook.
        instance._fileFields[fieldName] = false
        instance.markModified '_fileFields'
        return cb()
    else
      return cb()


  #
  # Delete all files uploaded to file fields before the object is removed.
  #
  schema.pre 'remove', true, (next, done) ->
    debug 'in file field pre-remove hook'
    instance = this

    # Delete each file field's file asynchronously.

    # Make an array of the names of filled fields so I don't have problems
    # making the async task functions.
    filledFields = []
    for fieldName, filled of instance._fileFields
      if filled
        if typeof instance[fieldName] == 'object' &&
        typeof instance[fieldName].fileName == 'string'
          # We've passed a basic check that there is a file object stored in
          # modelinstance.fieldName
          filledFields.push fieldName

    debug 'filledFields: ', filledFields
    # Clear the _fileFields object to prevent other instances of this callback
    # from trying to do all of this as well.
    instance._fileFields = {}
    # Fire off the next remove middleware, if any.
    next()

    asyncTasks = []
    filledFields.forEach (fieldName)->
      asyncTasks.push (cb)->
        debug 'in async delete task'
        debug 'fieldName: ', fieldName
        instance.clearff fieldName, cb

    return async.parallel asyncTasks, ()->
      return done()

module.exports = plugin
