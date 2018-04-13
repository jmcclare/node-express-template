# mongoose-image-attachments #

Mongoose Image Attachments is an image file attachments plugin for
[Mongoose.js](http://mongoosejs.com/). It adds an `images` array to your
Mongoose schema. It also adds methods for attaching, linking and deleting image
file attachments. It lets you store your images in any number of alternate
sizes.


## Usage ##

In the file where you define your schema. In this example, we'll call it
`postSchema` and the `Post` model.

    iAttachments = require 'mongoose-image-attachments'

    # Define the schema
    postSchema = mongoose.Schema
      name:
        type: String
        required: true

    # Set the options.
    # See image-store lib for available options.
    iaOptions =
      formats:
        embedded:
          width: 500
        thumbnail:
          width: 80
          height: 50
      fileStoreOptions:
        collection: 'car'

    # Add the image attachments plugin
    postSchema.plugin iAttachments, iaOptions

    Post = mongoose.model('Post', postSchema)

    module.exports = Post

See the image-store and file-store libraries for available options. file-store
options go in the `fileStoreOptions` parameter of your image-store options
object. Each of these libraries have defaults and store their own set of
changeable options. If you pass no options for them here you will use whatever
options the global objects for those libraries have set.

### Plugin Options ###

This plugin uses the `ImageStore` class, which uses `FileStore` to store the
files. See their documentation for available options.

The only difference is that this plugin sets the `FileStore`'s `collection`
option to 'image' by default.

### Functions ###

To attach a new image, in a route that handles a file upload form:

    if req.files.image1.length > 0
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

To get the URL of an attached image's regular size:

    image5URL = post.attachedImageURL post.images[5]

Or:

    image5URL = post.attachedImageURL 5

Or:

    image5URL = post.attachedImageURL 5, 'embedded'

To get the URL of an attached image's thumbnail:

    image5URL = post.attachedImageURL post.images[5], 'thumb'

To get the URL of an attached image's original file:

    image5URL = post.attachedImageURL post.images[5], 'original'

Or:

    image5URL = post.attachedImageURL post.images[5]

To delete an attached image:

    post.deleteAttachedImage post.images[0], (err) ->
      if err
        console.log err
      # Do more stuff
      ...

Or:

    post.deleteAttachedImage 3, (err) ->
      if err
        console.log err
      # Do more stuff
      ...
