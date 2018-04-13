
# Standard packages

path = require 'path'


# Node packages

async = require 'async'


# local packages

tools = require 'tools'
imageStore = require 'image-store'


#
# Some options will be passed on to ImageStore. See ImageStore and FileStore
# docs for details on those. Note that you can set none and use whatever
# default or system wide options ImageStore has set.
#
plugin = (schema, suppliedOptions) ->
  schema.add images: []

  options = {}

  # For now, pass the options directly on to ImageStore and FileStore. Let
  # those check them.  TODO: write a function to parse options.
  if suppliedOptions
    options = suppliedOptions

  if options.fileStoreOptions
    if ! options.fileStoreOptions.collection
      options.fileStoreOptions.collection = 'image'
  else
    options.fileStoreOptions = {}


  schema.methods.attachImage = (attachmentInfo, cb) ->
    modelInstance = this
    if (!attachmentInfo || typeof(attachmentInfo) != 'object')
      return cb new Error 'attachmentInfo is not valid'
    if (typeof(attachmentInfo.path) != 'string')
      return cb new Error 'attachmentInfo has no valid path'

    tools.clone options, (err, currentOptions) ->
      return cb err if err

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

      imageStore.store attachmentInfo.path, currentOptions, (err, image) ->
        return cb err if err
        modelInstance.images.push image
        return cb null, modelInstance


  #
  # Return the URL that points to this file.
  #
  # @params
  #   item - image object or integer index of image
  #   format - {optional} - string name of the image format to get a URL for.
  #
  # @returns
  #   URL of the image or blank if none found.
  #
  # Since this is probably going to be used in templates, I though it best to
  # avoid throwing errors and simply return an empty string. It will make
  # errors more cryptic, but at least pages will be less likely to break due to
  # small problems.
  #
  # A better strategy is to make custom Error object types and return them here
  # and have a helper function in the image-store (and file-store) libraries
  # that will stick to empty strings. For now, blank strings here will do.
  #
  # item can be either an image object from the images array, or the index of an
  # item in that array. For example:
  #
  #   image1URL = post.attachedImageURL post.images[0]
  #
  #   image3URL = post.attachedImageURL 2
  #
  #   image3EmbedURL = post.attachedImageURL 2, 'embedded'
  #
  schema.methods.attachedImageURL = (item, format) ->
    instance = this

    switch typeof item
      when 'object'
        image = item
      when 'number'
        # Make sure the item is in the array.
        if ! instance.images[item]
          # Item does not exist in images list.
          # There is no callback to pass an error to, so just return blank.
          return ''
        else
          image = instance.images[item]
      else
        # Invalid index type.
        # There is no callback to pass an error to, so just return blank.
        return ''

    if format
      if typeof format != 'string'
        return ''

    try
      return imageStore.pubPath image, { format: format }
    catch err
      return ''


  #
  # Delete an attached image.
  #
  # item can be either an image object from the files array, or the index of an
  # item in that array. For example:
  #
  #   post.deleteAttachedImage post.images[0], (err) ->
  #     if err
  #       console.log err
  #     # Do more stuff
  #     ...
  #
  # Or:
  #
  #   post.deleteAttachedImage 3, (err) ->
  #     if err
  #       console.log err
  #     # Do more stuff
  #     ...
  #
  schema.methods.deleteAttachedImage = (item, cb) ->
    instance = this

    switch typeof item
      when 'object'
        image = item
        # Make sure the file exists in the images array.
        index = instance.images.indexOf image
        if index == -1
          error = new Error 'Item does not exist in images list.'
          return cb error
      when 'number'
        # Make sure the item is in the array.
        if ! instance.images[item]
          error = new Error 'Item does not exist in images list.'
          return cb error
        else
          image = instance.images[item]
          index = item
      else
        error = new Error 'Invalid index type.'
        return cb error

    return imageStore.delete image, (err) ->
      return cb err if err

      # Clear the item in the `images` array.
      instance.images.set index, null

      return cb null


  #
  # Delete all attached images before the object is removed.
  #
  schema.pre 'remove', true, (next, done) ->
    modelInstance = this
    # Fire off the next remove middleware, if any.
    next()

    if modelInstance.images.length > 0
      # Delete each image asynchronously
      
      asyncTasks = []
      # NOTE: For some reason, if we do this loop using `for image in
      # modelinstance.images`, every function we create will end up using the
      # last value assigned to `image` by the loop.
      modelInstance.images.forEach (image) ->
        if image
          asyncTasks.push (cb) ->
            modelInstance.deleteAttachedImage image, cb

      return async.parallel asyncTasks, () ->
        return done()
    else
      return done()

module.exports = plugin
