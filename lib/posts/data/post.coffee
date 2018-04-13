#
# Model for posts.
#

# Node Packages
mongoose = require 'mongoose'
path = require('path')
#attachments = require('mongoose-attachments-localfs')
attachments = require 'mongoose-file-attachments'
imageAttachments = require 'mongoose-image-attachments'
#ObjectId = mongoose.Schema.Types.ObjectId
#marked = require 'marked'
#jade = require 'jade'
ftf = require 'mongoose-ftf'
ff = require 'mongoose-file-field'


postSchema = mongoose.Schema
  name:
    type: String
    required: true
  anarray: []

postSchema.plugin attachments, {collection: 'post-file-attachment'}

iaOptions =
  formats:
    embedded:
      width: 500
    thumbnail:
      width: 80
      height: 50
      fileType: 'JPEG'
  fileStoreOptions:
    collection: 'post-image-attachment'
postSchema.plugin imageAttachments, iaOptions

postSchema.plugin ftf, { fieldName: 'summary' }

postSchema.plugin ftf, { fieldName: 'message' }

postSchema.plugin ff,
  fieldName: 'download1'
  fileStoreOptions:
    collection: 'post-download1'
postSchema.plugin ff,
  fieldName: 'download2'
  fileStoreOptions:
    collection: 'post-download2'

Post = mongoose.model('Post', postSchema)


module.exports = Post
