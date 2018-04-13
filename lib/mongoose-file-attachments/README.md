# mongoose-file-attachments #

Mongoose Attachments is a file attachments plugin for
[Mongoose.js](http://mongoosejs.com/). It adds a `files` array to your Mongoose
schema. It also adds methods for attaching, linking and deleting file
attachments.


## Usage ##

In the file where you define your schema. In this example, we'll call it
`postSchema` and the `Post` model.

    attachments = require 'mongoose-file-attachments'

    # Define the schema
    postSchema = mongoose.Schema
      name:
        type: String
        required: true

    # Set the options
    aOptions = { collection: 'post' }

    # Add the attachments plugin
    postSchema.plugin attachments, aOptions

    Post = mongoose.model('Post', postSchema)

    module.exports = Post

See the FileStore docs for more details on the available options.

### Plugin Options ###

Currently, this plugin passes its options directly to `FileStore` when storing
files. You can omit the options object completely and use the whatever options
the `file-store` module's global `FileStore` object has set. For available
options, see the `file-store` docs.

 The most likely options you will want to fill in this object are
`collection` and maybe `subCollection`.

### Functions ###

To attach a new file, in a route that handles a file upload form:

    if req.files.file1.length > 0
      post.attachFile req.files.file1, (err) ->
        if err
          console.log err
          req.flash 'error', 'Error attaching file 1.'
        post.save (err) ->
          if err
            console.log err
            req.flash 'error', 'Post could not be saved.'
          else
            req.flash 'info', 'Post saved.'
          return res.redirect app.locals.urls['posts']

You can also pass an options object to `attachFile()` as the second argument.
You can override any of the options you set when you called the plugin, but
it's better to leave any non file-specific options the same for every file.

The `fileName` option sets the name of the file the attachment will be stored
under, but it might be better to let the plugin get that from Node's attachment
info object. FileStore will turn it into a web friendly name if it's not
already.

To get the URL of an attached file:

    file5URL = post.attachedFileURL post.files[5]

Or:

    file5URL = post.attachedFileURL 5

To delete an attached file:

    post.deleteAttachedFile post.files[0], (err) ->
      if err
        console.log err
      # Do more stuff
      ...

Or:

    post.deleteAttachedFile 3, (err) ->
      if err
        console.log err
      # Do more stuff
      ...
