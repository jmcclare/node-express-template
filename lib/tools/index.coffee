tools = require('./lib/clone')
clone = tools.clone
cloneSync = tools.cloneSync
merge = tools.merge
mergeSync = tools.mergeSync


module.exports = exports =
  clone: clone
  cloneSync: cloneSync
  merge: merge
  mergeSync: mergeSync
