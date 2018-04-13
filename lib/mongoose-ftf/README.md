# mongoose-ftf #

mongoose-ftf is a formatted text field plugin for
[Mongoose.js](http://mongoosejs.com/). It adds a dictionary field to your
schema that stores the original text, the method to format it with (markdown,
jade, etc.) and the filtered text.


## Usage ##

In the file where you define your schema. In this example, we'll call it
`postSchema` and the `Post` model.

    ftf = require 'mongoose-ftf'

    # Define the schema
    postSchema = mongoose.Schema
      name:
        type: String
        required: true

    # Add the ftf plugin
    postSchema.plugin ftf, { fieldName: 'message' }

    Post = mongoose.model('Post', postSchema)

    module.exports = Post

This will add a new nested field named `message`.

To update this field, update `message.base` with the formatted input text. Set `message.format` to the format of the text ("markdown", "jade", or blank for unfiltered text).

    post.message.format = 'markdown'
    post.message.base = '# Some Markdown Text #'
    # Save the instance to have the text compiled
    post.save()
    # The compiled text is now available in post.message.compiled

When you save the model instance, it will compile the text in `message.base`
using the format you specified in `message.format` and store it in
`message.compiled`. You only have to set `message.format` once. Once you save
the object, you can use the compiled text in `message.compiled`.

### Options ###

`fieldName`: The name of the field that will be added to the model. Defaults to
'body'

`defaultFormat`: The format this field will get if not set to anything else.
Defaults to `'markdown`'. This can be set to `''` for unfiltered text. To
change the format of the field in any model instance, change
`modelInstance.<fieldname>.format`.

`required`: Whether or not `<fieldname>.base` must be filled in. Defaults to
`false`.

`ftags`: Whether or not to filter file attachment tags. Defaults to `true`. See
below for more on these.

`itags`: Whether or not to filter image attachment tags. Defaults to `true`.
See below for more on these.


## File Attachments ##

This plugin will detect Jonathan McClare's mongoose-file-attachments plugin and
convert all file URL tags to the full URLs for the attached files.  For
example, to insert a markdown link to attached file 6, you put this in your
base text:

    A link to [attached file 6](#{furl:6})

The text `#{furl:6}` will be replaced with the full URL of attached file 6.

To have the text "#{furl:3}" show up without being filtered, you do the same
as you do in Jade syntax. Place a backslash before the opening `#`.

    The text for a URL that will not be filtered: \#{furl:3}

It will show up as `#{furl:3}` in the compiled text. The compiler will remove
the `\`.


## Image Attachments ##

This plugin will detect Jonathan McClare's mongoose-image-attachments plugin
and convert all image URL tags to the full URLs for the attached images.  For
example, to insert a markdown image tag for attached image 6, you put this in
your base text:

    ![Alt text](#{iurl:6})

The text `#{iurl:6}` will be replaced with the full URL of attached image 6.

By default, it will look for an image format named `embedded` and return that
URL. If you want to specify a different format, such as `original`, use this
syntax:

    ![Alt text](#{iurl:6:original})

You can use the same preceding `\` to have these tags show up unfiltered in the
output.
