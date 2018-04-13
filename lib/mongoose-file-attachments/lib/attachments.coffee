
# Standard packages


# Node packages

async = require 'async'


# local packages

fileStore = require 'file-store'
tools = require 'tools'


#
# Options will be passed on to FileStore. See FileStore docs for details on
# those.  Note that you can set none and use whatever default or system wide
# options FileStore has set.
#
plugin = (schema, suppliedOptions) ->
  schema.add files: []

  options = {}

  # Pass the options directly on to FileStore. Let that check them.
  if suppliedOptions
    options = suppliedOptions


  schema.methods.attachFile = (attachmentInfo, cb) ->
    modelInstance = this
    if (!attachmentInfo || typeof(attachmentInfo) != 'object')
      return cb new Error 'attachmentInfo is not valid'
    if (typeof(attachmentInfo.path) != 'string')
      return cb new Error 'attachmentInfo has no valid path'

    tools.clone options, (err, currentOptions) ->
      return cb err if err

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

      fileStore.store attachmentInfo.path, currentOptions, (err, file) ->
        return cb err if err
        modelInstance.files.push file
        return cb null, modelInstance


  #
  # Return the URL that points to this file.
  #
  # item can be either a file object from the files array, or the index of an
  # item in that array. For example:
  #
  #   file1URL = post.attachedFileURL post.files[0]
  #
  # Or:
  #
  #   file1URL = post.attachedFileURL 7
  #
  schema.methods.attachedFileURL = (item) ->
    instance = this

    switch typeof item
      when 'object'
        file = item
      when 'number'
        # Make sure the item is in the array.
        if ! instance.files[item]
          # Item does not exist in attachments list.
          # There is no callback to pass an error to, so just return blank.
          return ''
        else
          file = instance.files[item]
      else
        # Invalid index type.
        # There is no callback to pass an error to, so just return blank.
        return ''

    return fileStore.pubPath file, options


  #
  # Delete an attached file.
  #
  # item can be either a file object from the files array, or the index of an
  # item in that array. For example:
  #
  #   post.deleteAttachedFile post.files[0], (err) ->
  #     if err
  #       console.log err
  #     # Do more stuff
  #     ...
  #
  # Or:
  #
  #   post.deleteAttachedFile 3, (err) ->
  #     if err
  #       console.log err
  #     # Do more stuff
  #     ...
  #
  schema.methods.deleteAttachedFile = (item, cb) ->
    instance = this

    switch typeof item
      when 'object'
        file = item
        # Make sure the file exists in the attachments array.
        index = instance.files.indexOf file
        if index == -1
          error = new Error 'Item does not exist in attachments list.'
          return cb error
      when 'number'
        # Make sure the item is in the array.
        if ! instance.files[item]
          error = new Error 'Item does not exist in attachments list.'
          return cb error
        else
          file = instance.files[item]
          index = item
      else
        error = new Error 'Invalid index type.'
        return cb error

    return fileStore.delete file, options, (err) ->
      return cb err if err

      # Clear the item in the `files` array.
      instance.files.set index, null

      return cb null


  #
  # Delete all attached files before the object is removed.
  #
  schema.pre 'remove', true, (next, done) ->
    modelInstance = this
    # Fire off the next remove middleware, if any.
    next()

    if modelInstance.files.length > 0
      # Delete each file asynchronously
      
      asyncTasks = []
      # NOTE: For some reason, if we do this loop using `for file in
      # modelinstance.files`, every function we create will end up using the
      # last value assigned to `file` by the loop.
      modelInstance.files.forEach (file) ->
        if file
          asyncTasks.push (cb) ->
            modelInstance.deleteAttachedFile file, cb

      return async.parallel asyncTasks, () ->
        return done()
    else
      return done()

module.exports = plugin
