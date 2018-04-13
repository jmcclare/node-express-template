# upload #

A library for helping deal with file uploads. This uses Multer to parse request
bodies.


## Usage ##

Before declaring any routes that take file uploads, call this:

    upload = require 'upload'
    
    # app is your Express app instance
    upload.setUpTmp app

That will ensure the upload temporary directory is defined and that the
directory exists on disk. The default upload temp dir is `/tmp/node-upload`. If you want to use something else, set it before you call `setUpTmp` with:

    app.set 'upTmp', '/path/to/your/upload/temp/dir'

On any route that takes file uploads, add the `cleanUploads` middleware after
any middleware that deals with the uploaded files. Make sure any middleware
before this calls `next()`. For example:

    multerOptions =
      dest: app.get 'upTmp'
    app.post '/profile',
      multer multerOptions,
      (req, res, next)->

        # Code that stores uploads and sends response
        # ...

        next()
      ,
      upload.cleanUploads()

Remember to call `cleanUploads()`. It's a function that returns a middleware
function. By default, it will not call `next()` because it is intended to be
called last, after your response middleware. If you want it to call `next()`
when it's finished its job, pass it `true`, like this:

    cleanUploads true

Multer works the same way `bodyParser` used to. Regular form fields are placed
in `req.body`. Uploaded files are stored in the temporary directory (which we
set to `upTmp`) and made available in `req.files`.

As you can see, it is up to you to tell multer to use `upTmp`. Even if you
don't, `cleanUploads` will still be able to delete any left over temporary
uploaded files.

If you want, you can call the middleware directly from another middleware by
calling `cleanUploads()` and chaining the parameters to it:

    upload.cleanUploads()(req, res, next)

You can also ensure any single file has been deleted by calling `ensureDeleted`
directly:

    upload.ensureDeleted filePath
