# standard packages

path = require 'path'
debug = require('debug')('file-store')

# npm packages

fs = require 'fs.extra'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
uuid = require 'uuid'

# Our slug generator. See https://github.com/jeremys/uslug
# The best alternative was the slug package. For more on that, see
# https://github.com/dodo/node-slug
uslug = require 'uslug'
# Default is '-_~'. Be a little less restrictive.
allowedFilenameChars = '-_~.'


# local packages

tools = require 'tools'


existsFn = fs.exists || path.exists
existsSync = fs.existsSync || path.existsSync


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

  if 'fileName' of suppliedOptions
    if typeof suppliedOptions.fileName != 'string'
      return cb new TypeError 'options.fileName must be a string.'

  if 'originalFileName' of suppliedOptions
    if typeof suppliedOptions.originalFileName != 'string'
      return cb new TypeError 'options.originalFileName must be a string.'

  if 'name' of suppliedOptions
    if typeof suppliedOptions.name != 'string'
      return cb new TypeError 'options.name must be a string.'

  if 'description' of suppliedOptions
    if typeof suppliedOptions.description != 'string'
      return cb new TypeError 'options.description must be a string.'

  if 'collection' of suppliedOptions
    if typeof suppliedOptions.collection != 'string'
      return cb new TypeError 'options.collection must be a string.'

  if 'subCollection' of suppliedOptions
    if typeof suppliedOptions.subCollection != 'string'
      return cb new TypeError 'options.subCollection must be a string.'

    # Return an error for a non-blank subCollection with a blank collection in
    # use. Check the one that is being used.
    if suppliedOptions.subCollection != ''
      if 'collection' of suppliedOptions &&
          suppliedOptions.collection == ''
        return cb new Error 'Cannot have a subCollection without a collection.'
      else
        if currentOptions.collection == ''
          return cb new Error 'Cannot have a subCollection without a collection.'

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
# collectionPath - gets the full local path to the collection directory
#   based on the supplied options.
#
# @param {object} options
# @api private
#
collectionPath = (options, file) ->
  if file
    # Note that files only have information pertaining to themselves and their
    # location within the store, but nothing about the location or options of
    # the entire store.
    collection = file.collection
    subCollection = file.subCollection
  else
    collection = options.collection
    subCollection = options.subCollection
  return path.join options.publicDir,
    options.fileDataDir, collection, subCollection

#
# FileStore constructor.
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
#     FileStore = () ->
#       @defaultOptions = {}
#       @options = tools.clone @defaultOptions
#
class FileStore
  constructor: (options) ->
    @defaultOptions =
      publicDir: path.join process.cwd(), 'public'
      fileDataDir: '_data'
      collection: 'attachment'
      subCollection: ''
      deleteOriginal: true
    @storedOptions = tools.cloneSync @defaultOptions
    if typeof options == 'object'
      @optionsSync options


# 
# Sets FileStore options
# 
# ####Example:
#     # sets the 'test' option to `value` 
#     fileStore.setOption 'test', value
# 
# @param {String} key
# @param {String} value
# @api public
# 
FileStore::setOption = (key, value) ->
  if arguments.length == 1
    return @storedOptions[key]
  @storedOptions[key] = value
  return @


# 
# Gets file-store options
# 
# ####Example:
# 
#     fileStore.getOption('test') # returns the 'test' value
# 
# @param {String} key
# @method get
# @api public
# 

FileStore::getOption = FileStore::setOption


# 
# Sets FileStore options with an object
# 
# ####Example:
#     newOptions = { newOption: 'some value', existingOption: 'text' }
#     fileStore.options newOptions, (err, options)->
#       # Do next stuff here
#       ...
# 
# @param {Object} (optional) newOptions
# @param {Function} callback
# @api public
# 
FileStore::options = () ->
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
  tools.merge @storedOptions, newOptions, (err, mergedOpts)->
    return cb err if err
    tools.clone curObj.storedOptions, (err, clonedOpts)->
      return cb err if err
      cb null, clonedOpts


# 
# Sets FileStore options with an object
# 
# ####Example:
# 
#     fileStore.options { newOption: 'some value', existingOption: 'text' }
#     options = fileStore.options
# 
# @param {Object} (optional) newOptions
# @api public
# 
FileStore::optionsSync = (newOptions) ->
  if arguments.length == 0
    return @storedOptions
  return tools.cloneSync tools.mergeSync @storedOptions, newOptions


# 
# Resets FileStore options to the defaults
# 
# @param {Object} (optional) newOptions
# @param {Function} callback
# @api public
# 
FileStore::resetOptions = () ->
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
# Resets FileStore options to the defaults
# 
# @param {Object} (optional) newOptions
# @api public
# 
FileStore::resetOptionsSync = () ->
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
# store - Stores a file
# 
# ####Examples:
# 
#     fileStore.store '/tmp/g54no43nonf43kler/tree.jpg', (err, id) ->
#       throw err if err
#       # Store the file object somehow
#       db.files.add file
# 
#     options = { collection: 'user-upload', subCollection: 'profile-pic' }
#     fileStore.store '/tmp/g54no43nonf43kler/tree.jpg', options, (err, id) ->
#       throw err if err
#       # Store the file object somehow
#       db.files.add file
#
# Remember that if you pass some options to store() regarding where to store a
# file you must pass those same options to pubPath and delete with the file's
# ID to correclty deal with the file.
# 
# @param path {string} path to file on local file system.
# @param options {object} (optional) object containing options for storing this
# file.
# @param callback {function} callbackfunction. Takes err {Error}, fileID
# {string}.
# @api public
# 
FileStore::store = (filePath, callback) ->
  if arguments.length == 3
    optionsSupplied = true
    suppliedOptions = arguments[1]
    cb = arguments[2]
  else
    optionsSupplied = false
    cb = arguments[1]

  stage2 = (options)->
    if ! options.fileName
      if options.originalFileName
        options.fileName = options.originalFileName
      else
        options.fileName = path.basename filePath

    if ! options.originalFileName
      options.originalFileName = options.fileName

    if ! options.description
      options.description = ''

    collectionDirPath = collectionPath options

    checkSourceFile = () ->
      existsFn filePath, (exists) ->
        if ! exists
          err = new fileStore.Error.FileMissingError()
          return cb err
        uniquePart = uuid.v4()
        # Make a directory for the file's UUID
        oldMask = process.umask 0o000
        fs.mkdir path.join(collectionDirPath, uniquePart), 0o775, (err) ->
          return cb err if err
          process.umask oldMask
          cleanFileName = uslug options.fileName, {allowedChars: allowedFilenameChars}
          if cleanFileName == ''
            cleanFileName = '_'
          if ! options.name
            options.name = cleanFileName
          tail = path.join uniquePart, cleanFileName
          storedPath = path.join collectionDirPath, tail
          if options.deleteOriginal
            storeFn = fs.rename
          else
            storeFn = fs.copy
          storeFn filePath, storedPath, (err) ->
            return cb err if err
            file =
              id: uniquePart
              fileName: cleanFileName
              originalFileName: options.originalFileName
              name: options.name
              description: options.description
              collection: options.collection
              subCollection: options.subCollection
            cb null, file

    existsFn collectionDirPath, (exists) ->
      if (!exists)
        # Clear the process' umask so that the mode we use below isn't masked.
        oldMask = process.umask 0o000
        mkdirp collectionDirPath, 0o775, (err, made) ->
          # Reset the process' umask
          process.umask oldMask
          return cb err if err
          checkSourceFile()
      else
        checkSourceFile()

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
# Returns a file's public path
#
# The public path is the path the file is stored at under the public directory.
#
# If the file is stored on the local file system at
# `/srv/www/example.com/public/_data/attachments/h97h43iuhq398h32/tree.jpg` and
# the public directory is `/srv/www/example.com/public,` this will return
# `/_data/attachments/h97h43iuhq398h32/tree.jpg` if you give it that file's ID.
# 
# ####Examples:
#     
#     # `file` is a file object passed to the callback function by store()
#     pubPath = fileStore.pubPath file 
#
#     # You can override the current FileStore's stored options when
#     # determining a pubPath by passing an optional options object.
#     options = { subCollection: 'image' }
#     pubPath = fileStore.pubPath fileID, options
#
# @param file {object} file object as returned by FileStore::store()
# @param options (optional) {object} options to override when determining this
#   file's pubPath.
#   NOTE: Currently `fileDataDir` is the only option you can supply that will
#   affect the output.
# @api public
# 
FileStore::pubPath = (file, suppliedOptions) ->
  if typeof suppliedOptions != 'undefined'
    optionsSupplied = true
    if typeof suppliedOptions != 'object'
      throw new TypeError 'options must be an object.'

  options = tools.cloneSync @storedOptions

  stage2 = (options) ->
    return path.join '/',
      options.fileDataDir
      file.collection
      file.subCollection
      file.id
      file.fileName

  if optionsSupplied
    cleanedOptions = checkSuppliedOptionsSync suppliedOptions, options
    options = tools.mergeSync options, cleanedOptions
    return stage2 options
  else
    return stage2 options


#
# deletes a file from the store
#
# ####Examples:
#
#     # file is an object passed to the callback function by store()
#     fileStore.delete file, (err) ->
#       if err
#         # handle error
#         ...
#       # file is deleted. Do next stuff.
#       ...
#
# @param file {object} file object as returned by FileStore::store().
# @param options {option} (optional) options to override when deleting this file.
#   NOTE: Currently there are no options that affect the operation.
# @param callBack {function} - function to call when finished. Takes:
#   * err - Error object, or null if no errors encountered.
# @api public
#
FileStore::delete = (file, cb) ->
  debug 'in FileStore::delete'
  if arguments.length == 3
    optionsSupplied = true
    suppliedOptions = arguments[1]
    cb = arguments[2]
  else
    optionsSupplied = false
    cb = arguments[1]

  stage2 = (options) ->
    collectionDirPath = collectionPath options, file

    filePath = path.join collectionDirPath, file.id, file.fileName
    dirPath = path.join collectionDirPath, file.id
    debug 'filePath: ', filePath

    existsFn filePath, (exists) ->
      if ! exists
        err = new fileStore.Error.FileMissingError()
        return cb err
    
      # delete the file's individual directory.
      rimraf dirPath, (err) ->
        return cb err if err
        return cb null

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
# The [FileStoreError](#error_FileStoreError) constructor.
# 
# @method Error
# @api public
# 
FileStore::Error = require './error'


# 
# The FileStore constructor
# 
# The exports of the file-store module is an instance of this class.
# 
# ####Example:
# 
#     fileStore = require 'file-store'
#     fileStore2 = new fileStore.FileStore()
# 
# @method FileStore
# @api public
# 
FileStore::FileStore = FileStore


# 
# The exports object is an instance of FileStore.
# 
# @api public
# 
fileStore = module.exports = exports = new FileStore
