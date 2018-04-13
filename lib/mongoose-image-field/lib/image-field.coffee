
# Standard packages

debug = require('debug')('mongoose-image-field')


# Node packages

async = require 'async'


# local packages

imageStore = require 'image-store'
tools = require 'tools'


plugin = (schema, options)->
  opType = typeof options
  if opType != 'undefined' && opType != 'object'
    throw new TypeError 'Invalid options supplied. Pass an object or omit options.'

  if typeof options.fieldName == 'undefined' || ! options.fieldName
    fieldName = 'image'
  else
    fieldName = options.fieldName

  # Make sure we have imageStore Options to work with, even if they're blank.
  if options.imageStoreOptions
    imageStoreOptions = options.imageStoreOptions
  else
    imageStoreOptions = {}
  debug 'imageStoreOptions: ', imageStoreOptions

  # Make sure no field with the same name exists before adding it.
  if schema.path fieldName
    throw new Error 'A field named ' + fieldName + ' already exists in this schema.'

  schemaAdditions = {}
  schemaAdditions[fieldName] = { type: {}, default: {}, imageStoreOptions: imageStoreOptions }
  schema.add schemaAdditions

  # Add an array field to track the image fields assigned to this schema.
  debug 'schema.path _imageFields', schema.path '_imageFields'
  if ! schema.path '_imageFields'
    schema.add
      _imageFields: { type: {}, default: {} }


  schema.methods.updateif = (fieldName, attachmentInfo, cb)->
    debug 'in updateif'
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

    # We ensured there are imageStoreOptions in the field schema, even if we
    # had to make them blank.
    imageStoreOptions = fieldSchema.options.imageStoreOptions
    debug 'imageStoreOptions: ', imageStoreOptions

    return tools.clone imageStoreOptions, (err, currentOptions) ->
      if err
        debug 'clone error: ', err
        return cb err
      debug 'cloned successfully'

      if attachmentInfo.originalname
        currentOptions.fileStoreOptions.originalFileName = attachmentInfo.originalname

      # multer has its own method of filtering the filename. The result of that
      # gets stored in attachmentInfo.name. I don't use that because it gets
      # set to the random temp filename if you don't give multer a function to
      # filter the original with.
      #
      # storedFileName is the name you want to store the file under. If this is
      # not filled in, we will use whatever FileStore defaults to –see
      # FileStore.store().
      if attachmentInfo.storedFileName
        currentOptions.fileStoreOptions.fileName = attachmentInfo.storedFileName

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
        debug 'storing image file...'
        return imageStore.store attachmentInfo.path, currentOptions, (err, image) ->
          debug 'in imageStore.store callback'
          return cb err if err
          debug 'image object: ', image
          modelInstance[fieldName] = image
          # Mark the field as filled for the pre-remove hook.
          modelInstance._imageFields[fieldName] = true
          modelInstance.markModified '_imageFields'
          return cb null, modelInstance

      if typeof modelInstance[fieldName] == 'object' && typeof modelInstance[fieldName].name == 'string'
        # There is an existing image file stored for this field. Delete it
        # before storing the new one.
        debug 'deleting existing image...'
        return imageStore.delete modelInstance[fieldName], imageStoreOptions, (err)->
          return cb err if err
          modelInstance[fieldName] = {}
          # Temporarily mark the field as empty for the pre-remove hook.
          modelInstance._imageFields[fieldName] = false
          modelInstance.markModified '_imageFields'
          return storeStage()
      else
        return storeStage()
