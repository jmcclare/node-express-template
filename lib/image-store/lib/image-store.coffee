# standard packages

# Place debug calls in this file under the 'image-store'
debug = require('debug')('image-store')
fs = require 'fs'
path = require 'path'


# npm packages

async = require 'async'
gm = require 'gm'
uuid = require 'uuid'


# local packages

tools = require 'tools'
fileStore = require 'file-store'


# Module functions / variables

existsFn = fs.exists || path.exists
existsSync = fs.existsSync || path.existsSync

supportedFormats = [ 'JPEG', 'PNG', 'GIF', 'BMP', 'PSD', 'XCF', 'TIFF', 'SVG' ]
supportedExtensions = [ 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'psd', 'xcf', 'tif', 'tiff', 'svg' ]

formatExtensions =
  'JPEG': 'jpg'
  'PNG':  'png'
  'GIF':  'gif'
  'BMP':  'bmp'
  'PSD':  'psd'
  'XCF':  'xcf'
  'TIFF': 'tiff'
  'SVG':  'svg'

supportedResizeTypes = [ 'default', 'force' ]


#
# Local Utility Functions
#


#
# This is the core option checking code that both functions below use.
#
# @api private
#
# @callback takes:
#   err - Error object, or null if no errors found
#
checkSuppliedOptionsCore = (suppliedOptions, currentOptions, cb) ->
  if typeof suppliedOptions != 'object'
    return cb new TypeError 'options must be an object.'
  if suppliedOptions instanceof Date
    return cb new TypeError("options cannot be a Date object.")
  if suppliedOptions instanceof Array
    return cb new TypeError("options cannot be an Array.")

  #if 'fileName' of suppliedOptions
    #if typeof suppliedOptions.fileName != 'string'
      #return cb new TypeError 'options.fileName must be a string.'
    #if suppliedOptions.fileName == ''
      #return cb new Error 'options.fileName cannot be blank.'

  if 'description' of suppliedOptions
    if typeof suppliedOptions.description != 'string'
      return cb new TypeError 'options.description must be a string.'

  if 'formats' of suppliedOptions
    if typeof suppliedOptions.formats != 'object'
      return cb new TypeError 'options.formats must be an object.'
    for name, format of suppliedOptions.formats
      if 'fileType' of format
        if typeof format.fileType != 'string'
          return cb new TypeError 'format fileType option must be a string.'
        if supportedFormats.indexOf(format.fileType) == -1
          return cb new Error 'Unsupported fileType option for ' + name + ' format.'

      if 'resizeType' of format
        if typeof format.resizeType != 'string'
          return cb new TypeError name + ' format resizeType is not a string.'
        if supportedResizeTypes.indexOf(format.resizeType) == -1
          return cb new Error 'Unsupported resizeType for ' + name + ' format.'

  return cb null


#
# Check options objects that can be supplied to store(), pubPath() and
# delete(). These options are always merged into the fileStore object's current
# options, so you need to supply those too to see if the combined set is valid.
#
# @param {object} suppliedOptions
# @param {object} currentOptions - your FileStore object's current options.
# @param {function} callback function, takes (err, cleanedOptions)
# @api private
#
checkSuppliedOptions = (suppliedOptions, currentOptions, cb) ->
  return checkSuppliedOptionsCore suppliedOptions, currentOptions, (err) ->
    return cb err if err

    # Clone the options object because we should be allowed to modify whatever is
    # passed on by this function. I may later sanitize certain options. I don't
    # want to modify the original object when I do that.
    return tools.clone suppliedOptions, (err, clonedOptions)->
      return cb err if err
      return cb null, clonedOptions


#
# Synchronous version of the above.
#
# @param {object} suppliedOptions
# @api private
#
checkSuppliedOptionsSync = (suppliedOptions, currentOptions) ->
  return checkSuppliedOptionsCore suppliedOptions, currentOptions, (err) ->
    throw err if err

    # Clone the options object because we should be allowed to modify whatever is
    # passed on by this function. I may later sanitize certain options. I don't
    # want to modify the original object when I do that.
    return tools.cloneSync suppliedOptions


#
# ImageStore constructor.
#
# Note that this syntax is necessary for the set and get methods to work as
# advertised.
#
# This creates a true JavaScript named function. I don't know exactly why, but
# without this, the prototype assignments do not work. I know that named
# functions are hoisted to the top of the current scope regardless of where
# they are declared, but I don't see how that matters when we're declaring it
# before all else.
#
# The other way to create an object (that didn't really work) looked like this:
#
#     ImageStore = () ->
#       @defaultOptions = {}
#       @options = tools.clone @defaultOptions
#
# Note that the CoffeeScript syntax `ImageStore::setOption` converts directly
# to `ImageStore.prototype.setOption` in JavaScript. You can even use the
# prototype format in CoffeeScript and get the same thing.
#
class ImageStore
  constructor: (options) ->
    @defaultOptions =
      resizeType: 'default'
      formats:
        embedded:
          width: 500
        thumbnail:
          width: 80
          height: 50
      fileStoreOptions:
        collection: 'image'
      gmOptions:
        imageMagick: true
    @storedOptions = tools.cloneSync @defaultOptions
    if typeof options == 'object'
      @optionsSync options


# 
# Sets ImageStore options
# 
# @param {String} key
# @param {String} value
# @api public
#
# The option you supply is merged into the stored options. If the option you
# supply has is a valid object for the format, gmOptions or fileStoreOptions
# options, the stored option will be completely replaced with what you
# supplied.
#
# If you want to clear those options set them to empty objects, ie. `{}`
# 
# ####Example:
#     # sets the 'test' option to `value` 
#     imageStore.setOption 'test', value
# 
ImageStore::setOption = (key, value)->
  if arguments.length == 1
    return @storedOptions[key]
  newOptions = {}
  newOptions[key] = value
  checkSuppliedOptionsSync newOptions, @storedOptions
  @storedOptions[key] = value
  return @


# 
# Gets image-store options
# 
# ####Example:
# 
#     imageStore.getOption('test') # returns the 'test' value
# 
# @param {String} key
# @method get
# @api public
# 

ImageStore::getOption = ImageStore::setOption


# 
# Sets ImageStore options with an object
#
# The options you supply are merged into the stored options. If the options
# object you supply has valid objects set for the format, gmOptions or
# fileStoreOptions properties, the stored properties will be completely
# replaced with what you supplied.
#
# If you want to clear those options set them to empty objects, ie. `{}`
#
# The same applies when setting these options with the setOption() and store()
# methods.
# 
# ####Example:
#     newOptions = { newOption: 'some value', existingOption: 'text' }
#     imageStore.options newOptions, (err, options)->
#       # Do next stuff here
#       ...
# 
# @param {Object} (optional) newOptions
# @param {Function} callback
# @api public
# 
ImageStore::options = () ->
  if arguments.length == 0
    throw new Error 'You must at least supply a callback function.'
  if arguments.length == 1
    return arguments[0] null, @storedOptions
  if arguments.length == 2
    newOptions = arguments[0]
    cb = arguments[1]
  if arguments.length > 2
    throw new Error 'Too many parameters.'

  curObj = @
  checkSuppliedOptions newOptions, @storedOptions, (err, cleanedOptions)->
    return cb err if err
    tools.merge curObj.storedOptions, cleanedOptions, (err, mergedOpts)->
      return cb err if err
      tools.clone curObj.storedOptions, (err, clonedOpts)->
        return cb err if err
        cb null, clonedOpts


# 
# Sets ImageStore options with an object
# 
# ####Example:
# 
#     imageStore.options { newOption: 'some value', existingOption: 'text' }
#     options = imageStore.options
# 
# @param {Object} (optional) newOptions
# @api public
# 
ImageStore::optionsSync = (newOptions) ->
  if arguments.length == 0
    return @storedOptions
  checkSuppliedOptionsSync newOptions, @storedOptions
  return tools.cloneSync tools.mergeSync @storedOptions, newOptions


# 
# Resets ImageStore options to the defaults
# 
# @param {Object} (optional) newOptions
# @param {Function} callback
# @api public
# 
ImageStore::resetOptions = () ->
  if arguments.length == 0
    throw new Error 'You must at least supply a callback function.'
  if arguments.length == 1
    newOptions = false
    cb = arguments[0]
  if arguments.length == 2
    newOptions = arguments[0]
    cb = arguments[1]
  if arguments.length > 2
    throw new Error 'Too many parameters.'

  @storedOptions = {}
  curObj = @
  return tools.clone @defaultOptions, (err, clonedOptions)->
    throw err if err
    if typeof newOptions == 'object'
      tools.merge clonedOptions, newOptions, (err, mergedOptions)->
        throw err if err
        return curObj.options mergedOptions, cb
    else
      return curObj.options clonedOptions, cb


# 
# Resets ImageStore options to the defaults
# 
# @param {Object} (optional) newOptions
# @api public
# 
ImageStore::resetOptionsSync = () ->
  if arguments.length == 0
    newOptions = false
  else
    newOptions = arguments[0]

  @storedOptions = {}
  curObj = @
  return tools.clone @defaultOptions, (err, clonedOptions)->
    throw err if err
    if typeof newOptions == 'object'
      tools.merge clonedOptions, newOptions, (err, mergedOptions)->
        throw err if err
        return curObj.optionsSync mergedOptions
    else
      return curObj.optionsSync clonedOptions


# 
# store - Stores an image file
# 
# @param path {string} path to file on local file system.
# @param options {object} (optional) object containing options for storing this
# file.
# @param callback {function} callbackfunction. Takes err {Error}, fileID
# {string}.
# @api public
#
# The options you supply are merged into a copy of the stored options and used
# for storing this image. They will also be stored with the image so you don't
# have to pass them again to the pubPath() or delete() methods. If the options
# object you supply has valid objects set for the format, gmOptions or
# fileStoreOptions properties what you supplied will be used instead of the
# stored options.
#
# If you want to clear those options set them to empty objects, ie. `{}`
# 
# ####Examples:
# 
#     imageStore.store '/tmp/g54no43nonf43kler/tree.jpg', (err, id) ->
#       throw err if err
#       # Store the image object somehow
#       db.files.add image
# 
#     options =
#       fileStoreOptions:
#         collection: 'user-upload'
#         subCollection: 'profile-pic'
#         name: 'tall-tree.jpg'
#       formats:
#         thumbnail:
#           width: 100
#           height: 80
#         header:
#           width: 500
#           height: 250
#           fileName: 'header.jpg'
#           fileFormat: 'JPEG'
#     imageStore.store '/tmp/g54no43nonf43kler/tree.jpg', options, (err, id) ->
#       throw err if err
#       # Store the image object somehow
#       db.files.add image
# 
ImageStore::store = (filePath, callback) ->
  if arguments.length == 3
    optionsSupplied = true
    suppliedOptions = arguments[1]
    cb = arguments[2]
  else
    optionsSupplied = false
    cb = arguments[1]

  # A sample debug call.
  debug 'store() filePath: ' + filePath

  # An object we will fill in with information on the original image. It is
  # declared here to be available to fApplyFormat.
  originalImage = {}

  # Returns a function to run in parallel to create formatted versions of
  # original image.
  fApplyFormat = (formatName, options)->
    return (pcb)->
      # do resizing, etc. here

      # The format object starts as the format options and eventually gets a
      # file object.
      format = options.formats[formatName]

      # Fill in dimensions from original if none specified.
      if ! format.width && ! format.height
        format.width = originalImage.width
        format.height = originalImage.height

      # Fill in missing fileFormat from original
      if ! format.fileType
        format.fileType = originalImage.fileFormat

      # This option is a string so I can later accomodate smart crop resizing
      # and maybe face aware smart crop resizing.
      switch format.resizeType
        when 'force' then forceSizeOp = '!'
        else forceSizeOp = ''

      # I will use the original file's directory as a temp dir.
      tmpDir = path.dirname filePath
      extension = formatExtensions[format.fileType]
      tmpFilePath = path.join tmpDir, uuid.v4() + '.' + extension

      gm(filePath)
      .options(options.gmOptions)
      .resize(format.width, format.height, forceSizeOp)
      .toBuffer (err, buffer)->
        return pcb err if err
        gm(buffer).options(options.gmOptions).size (err, size)->
          return pcb err if err
          # fill in the actual size of the final image
          format.width = size.width
          format.height = size.height

          gm(buffer).options(options.gmOptions).write tmpFilePath, (err)->
            return pcb err if err

            fileStore.store tmpFilePath,
              options.fileStoreOptions, (err, file)->
                return pcb err if err
                format.file = file
                return pcb null, [formatName, format]

  stage2 = (options)->
    image = {}
    image.fileStoreOptions = options.fileStoreOptions
    image.gmOptions = options.gmOptions

    # image.formats will be filled in below after the converted files for each
    # format have been stored.
    # image.name will be filled in below after the original file is stored with
    # FileStore. If options.name is blank we use whatever file.name was set to
    # by FileStore.
    
    if ! options.description
      options.description = ''
    image.description = options.description

    existsFn filePath, (exists) ->
      if ! exists
        err = new fileStore.Error.FileMissingError()
        return cb err

      fileExtension = path.extname filePath
      fileExtension = fileExtension.substr 1, fileExtension.len
      if supportedExtensions.indexOf(fileExtension) == -1
        error = new TypeError 'Unsupported file format.'
        return cb error

      gm(filePath).options(options.gmOptions).format (err, fileFormat)->
        return cb err if err

        gm(filePath).options(options.gmOptions).size (err, size)->
          return cb err if err
          if supportedFormats.indexOf(fileFormat) == -1
            error = new TypeError 'Unsupported file format.'
            return cb error

          #if ! options.formats.original
            #options.formats.original = {}
          # Add these details to serve as meta information. We won't be
          # resizing or changing the original.
          #options.formats.original =
            #width: size.width
            #height: size.height
            #fileFormat: fileFormat
          # Store this information in the originalImage object so fApplyFormat can use it. We'll also use it in the formats object in the final image object if it doesn't 
          originalImage.width = size.width
          originalImage.height = size.height
          originalImage.fileFormat = fileFormat

          # build array of functions that call applyFormat
          pOps = []
          for key, value of options.formats
            # Don't do the original here. The other formats need its source
            # file. We will store the original after the others are all done.
            #if key != 'original'
              ## keys are formatNames, values are formatOptions objects, but the
              ## formatter needs the full options object.
              #pOps.push fApplyFormat key, options
             
            pOps.push fApplyFormat key, options

          return async.parallel pOps, (err, results)->
            return cb err if err
            image.formats = {}
            for value in results
              image.formats[value[0]] = value[1]

            if image.formats.original
              if options.name
                image.name = options.name
              else
                image.name = image.formats.original.file.name
              fs.unlink filePath, (err)->
                return cb err if err
                return cb null, image
            else
              # Always store the original file –even if no format is defined
              # for it.
              fileStore.store filePath, options.fileStoreOptions, (err, file)->
                if err
                  return cb err
                else
                  # Set its format based on the information we read in the
                  # original image file.
                  image.formats.original = originalImage
                  image.formats.original.file = file
                  if options.name
                    image.name = options.name
                  else
                    image.name = file.name
                  return cb null, image

  return tools.clone @storedOptions, (err, options) ->
    return cb err if err

    if optionsSupplied
      checkSuppliedOptions suppliedOptions, options, (err, cleanedOptions) ->
        return cb err if err
        tools.merge options, cleanedOptions, (err, options) ->
          return cb err if err
          return stage2 options
    else
      return stage2 options


# 
# Returns an image's public path for a specified format.
#
# The public path is the path the image is stored at under the public directory.
#
# If the image is stored on the local file system at
# `/srv/www/example.com/public/_data/attachment/h97h43iuhq398h32/tree.jpg` and
# the public directory is `/srv/www/example.com/public,` this will return
# `/_data/attachments/h97h43iuhq398h32/tree.jpg` if you give it that file's ID.
# 
# ####Examples:
#     
#     # `image` is an image object passed to the callback function by store()
#     pubPath = imageStore.pubPath image 
#
#     # You can specify a specific format by passing an optional options
#     # object.
#     options = { format: 'thumbnail' }
#     pubPath = imageStore.pubPath image, options
#
#     # You can also override the current FileStore's stored options when
#     # determining a pubPath by adding a fileStoreOptions object parameter to
#     # your options object. See FileStore::pubPath to see what options FileStore
#     # takes here.
#     options = {
#       format: 'embedded'
#       fileStoreOptions:
#         fileDataDir: '_dynamic'
#     }
#     pubPath = imageStore.pubPath image, options
#
# @param image {object} image object as returned by ImageStore::store()
# @param options (optional) {object} options to use when determining this
#   image's pubPath.
#   format - image format to get path for. It must be a format defined for this
#     image. Defaults to 'original'
#   fileStoreOptions - optional options object passed to FileStore. See
#     FileStore::pubPath for available options.
# @api public
# 
ImageStore::pubPath = (image, suppliedOptions) ->
  if typeof suppliedOptions != 'undefined'
    optionsSupplied = true
    if typeof suppliedOptions != 'object'
      throw new TypeError 'options must be an object.'
    if suppliedOptions.format
      if typeof suppliedOptions.format != 'string'
        throw new TypeError 'format must be a string.'
      if typeof image.formats[suppliedOptions.format] == 'undefined'
        throw new ReferenceError 'format does not exist.'

  # Use fileStoreOptions in this order of priority: supplied, image's.
  # The imageStore's options should never be necessary.

  options = tools.cloneSync @storedOptions
  # Start with the image's fileStoreOptions. If the options parameter contains
  # a fileStoreOptions object, that will be used instead after it's merged in
  # below.
  options.fileStoreOptions = tools.cloneSync image.fileStoreOptions

  stage2 = (options) ->
    # For now, just use the 'original' format.
    #return fileStore.pubPath image.formats.original.file, options.fileStoreOptions

    if options.format
      format = options.format
    else
      format = 'original'
    return fileStore.pubPath image.formats[format].file, options.fileStoreOptions

  if optionsSupplied
    cleanedOptions = checkSuppliedOptionsSync suppliedOptions, options
    options = tools.mergeSync options, cleanedOptions
    return stage2 options
  else
    return stage2 options


#
# deletes an image's files from the store
#
# ####Examples:
#
#     # image is an object passed to the callback function by store()
#     imageStore.delete image, (err) ->
#       if err
#         # handle error
#         ...
#       # files are deleted. Do next stuff.
#       ...
#
# @param image {object} image object as returned by ImageStore::store().
# @param options {option} (optional) options to override when deleting this image.
#   NOTE: Currently there are no options that affect the operation.
# @param callBack {function} - function to call when finished. Takes:
#   * err - Error object, or null if no errors encountered.
# @api public
#
ImageStore::delete = (image, cb) ->
  if arguments.length == 3
    optionsSupplied = true
    suppliedOptions = arguments[1]
    cb = arguments[2]
  else
    optionsSupplied = false
    cb = arguments[1]

  stage2 = (options)->
    # call fileStore.delete in parallel to delete all of the image files.

    deleter = (name, format)->
      return (pcb)->
        fileStore.delete format.file, options.fileStoreOptions, (err)->
          return pcb err if err
          return pcb()

    # build array of functions that call fileStore.delete()
    pOps = []
    for key, value of image.formats
      pOps.push deleter key, value

    return async.parallel pOps, (err, results)->
      return cb err if err
      for value in results
        if value
          # An error ocurred deleting an image file
          return cb value
        return cb()

  # Use fileStoreOptions in this order of priority: supplied, image's.
  # The imageStore's options should never be necessary.
  return tools.clone @storedOptions, (err, options) ->
    return cb err if err

    # Start with the image's fileStoreOptions. If the options parameter
    # contains a fileStoreOptions object, that will be used instead after it's
    # merged in below.
    options.fileStoreOptions = image.fileStoreOptions

    if optionsSupplied
      checkSuppliedOptions suppliedOptions, options, (err, cleanedOptions) ->
        return cb err if err
        tools.merge options, cleanedOptions, (err, options) ->
          return cb err if err
          return stage2 options
    else
      return stage2 options


# 
# The [ImageStoreError](#error_ImageStoreError) constructor.
# 
# @method Error
# @api public
# 
ImageStore::Error = require './error'


# 
# The ImageStore constructor
# 
# The exports of the image-store module is an instance of this class.
# 
# ####Example:
# 
#     imageStore = require 'image-store'
#     imageStore2 = new imageStore.ImageStore()
# 
# @method ImageStore
# @api public
# 
ImageStore::ImageStore = ImageStore


# 
# The exports object is an instance of ImageStore.
# 
# @api public
# 
imageStore = module.exports = exports = new ImageStore
