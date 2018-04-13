async = require 'async'
debug = require('debug')('tools-clone')


cloneSync = (obj) ->
  # Handle the 3 simple types, and null or undefined
  if (null == obj || "object" != typeof obj)
    return obj

  # Handle Date
  if (obj instanceof Date)
    copy = new Date()
    copy.setTime(obj.getTime())
    return copy

  # Handle Array
  if (obj instanceof Array)
    copy = []
    for key, value of obj
      copy[key] = cloneSync obj[key]
    return copy

  # Handle Object
  if (obj instanceof Object)
    copy = {}
    #for attr in obj
    for attr of obj
      if (obj.hasOwnProperty(attr))
        copy[attr] = cloneSync(obj[attr])
    return copy

  throw new TypeError("Unable to copy obj. Its type isn't supported.")


clone = (obj, cb)->
  debug 'in clone'
  # Handle the 3 simple types, and null or undefined
  if (null == obj || "object" != typeof obj)
    return cb null, obj

  # Handle Date
  if (obj instanceof Date)
    copy = new Date()
    copy.setTime(obj.getTime())
    return cb null, copy

  # Function that returns a function to call clone and call back with a tuple
  # (two item array) of the object (or array) key and the copied value.
  cloner = (key, value)->
    return (pcb)->
      return clone value, (err, copy)->
        return pcb err if err
        return pcb null, [key, copy]

  # Handle Array asynchronously
  if (obj instanceof Array)

    # build array of functions that call clone
    pOps = []
    for key, value of obj
      pOps.push cloner key, value

    return async.parallel pOps, (err, results)->
      return cb err if err
      copy = []
      for value in results
        copy[value[0]] = value[1]
      return cb null, copy

  if (obj instanceof Object)
    debug 'obj is an Object'
    pOps = []
    for attr of obj
      if (obj.hasOwnProperty(attr))
        pOps.push cloner attr, obj[attr]

    return async.parallel pOps, (err, results)->
      return cb err if err
      copy = {}
      for value in results
        copy[value[0]] = value[1]
      return cb null, copy

  err = new TypeError("Unable to copy obj. Its type isn't supported.")
  return cb err, null


mergeSync = (base, updates) ->
  if 'object' != typeof updates
    throw new TypeError("Unable to merge updates. updates must be an object.")
  if updates instanceof Date
    throw new TypeError("Unable to merge updates. updates cannot be a Date object.")
  if updates instanceof Array
    throw new TypeError("Unable to merge updates. updates cannot be an Array.")
  if 'object' != typeof base
    throw new TypeError("Unable to merge into base. base must be an object.")
  if base instanceof Array
    throw new TypeError("Unable to merge into base. base cannot be an Array.")

  for attr of updates
    if (updates.hasOwnProperty(attr))
      base[attr] = cloneSync(updates[attr])

  return base


merge = (base, updates, cb)->
  if 'object' != typeof updates
    return cb new TypeError("Unable to merge updates. updates must be an object.")

  # Note: To get an object's class name, use:
  #     cls = Object.prototype.toString.call(obj).slice 8, -1
  # Date and Array are special in that typeof gives the same class name that
  # this does.

  if updates instanceof Date
    return cb new TypeError("Unable to merge updates. updates cannot be a Date object.")
  if updates instanceof Array
    return cb new TypeError("Unable to merge updates. updates cannot be an Array.")
  if 'object' != typeof base
    return cb new TypeError("Unable to merge into base. base must be an object.")
  if base instanceof Array
    return cb new TypeError("Unable to merge into base. base cannot be an Array.")

  # Function that returns a function to call clone and call back with a tuple
  # (two item array) of the object key and the copied value.
  cloner = (key, value)->
    return (pcb)->
      clone value, (err, copy)->
        return pcb err if err
        pcb null, [key, copy]

  pOps = []
  for attr of updates
    if (updates.hasOwnProperty(attr))
      # add a function that clones this attribute to an array
      pOps.push cloner attr, updates[attr]

  # use aync.parallel to call all of the functions in parallel
  # add the cloned attributes to base
  return async.parallel pOps, (err, results)->
    return cb err if err
    for value in results
      base[value[0]] = value[1]
    return cb null, base

  return cb null, mergedBase


module.exports = exports =
  clone: clone
  cloneSync: cloneSync
  merge: merge
  mergeSync: mergeSync
