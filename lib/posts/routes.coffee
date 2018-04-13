# 
# Module dependencies.
# 

# Standard modules
os   = require 'os'
fs   = require 'fs'
path = require 'path'
debug = require('debug')('post-routes')

# npm packages
bodyParser = require 'body-parser'
nodemailer = require 'nodemailer'
mongoose   = require 'mongoose'
multer     = require 'multer'

# local libraries
urls = require 'urls'
Post = require('posts/data').Post
upload = require 'upload'


existsFn   = fs.exists || path.exists
existsSync = fs.existsSync || path.existsSync


#
# Assign our default set of contact routes to the app under parentPath, or the
# default parentPath.
#
assign = (app, parentPath) ->
  parentPath = "/post" unless parentPath
  if ! app.locals.urls
    urls.addHelpers app
  #app.locals.urls['contact'] = parentPath + "/"
  app.locals.urls['posts'] = parentPath
  app.locals.urls['posts.delete'] = app.locals.urls['posts'] + '/delete'

  # Factoring this out.
  title = 'File Post Test'
  section = 'posts'
  name = ''
  email = ''
  summary = ''
  message = ''
  alertMessages = ''
  errorMessages = ''
  fieldErrors =
    name: ''
    email: ''
    summary: ''
    message: ''
  posts = {}
  renderForm = (res) ->
    Post.find {}, (err, posts) ->
      if err
        req.flash 'error', "Couldn't retrieve posts."
      return res.render 'posts',
        title: title
        section: section
        name: name
        email: email
        summary: summary
        message: message
        alertMessages: alertMessages
        errorMessages: errorMessages
        fieldErrors: fieldErrors
        posts: posts

  app.get app.locals.urls['posts'], (req, res, next) ->
    title = 'File Post Test'
    section = 'posts'
    # Reset these between requests.
    name = ''
    email = ''
    summary = ''
    message = ''
    alertMessages = ''
    errorMessages = ''
    fieldErrors =
      name: ''
      email: ''
      summary: ''
      message: ''
    return renderForm(res)

  # New post handler I need to fill in when I find a working multipart form
  # handler.
  #app.post '/old-posts', (req, res, next)->
  app.post app.locals.urls['posts'],
    multer
      dest: app.get 'upTmp'
      onParseEnd: (req, next)->
        curTime = new Date()
        debug 'multer form parsing completed at: ' + curTime
        debug req.body
        debug req.files
        #res.redirect app.locals.urls['posts']
        return next()
    (req, res, next)->
      title = 'File Post Test'
      section = 'posts'
      # Reset these between requests.
      name = ''
      email = ''
      summary = ''
      message = ''
      alertMessages = ''
      errorMessages = ''
      fieldErrors =
        name: ''
        email: ''
        summary: ''
        message: ''

      # Handle user input errors.
      #console.log req.body
      if ! req.body.name
        fieldErrors['name'] = 'Please fill in your name.'
      # Regular expression comes from Stack Overflow:
      # http://stackoverflow.com/questions/46155/validate-email-address-in-javascript
      re = /[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/
      #if ! re.test(req.body.email)
        #fieldErrors['email'] = 'Please fill in a valid email address.'
      #if ! req.body.message
        #fieldErrors['message'] = 'Please fill in a valid message.'
      if errorMessages
        renderForm(res)
        return next()
      for type,error of fieldErrors
        if error
          name = req.body.name
          email = req.body.email
          summary = req.body.summary
          message = req.body.message
          renderForm(res)
          return next()

      # Create a new Post record
      preppedPost =
        name: req.body.name
        'summary.base': req.body.summary
        'message.base': req.body.message
        'message.format': req.body.messageFormat

      dummy = new Post preppedPost
      dummy.anarray.addToSet 'a string', 'another string'
      dummy.anarray.push 'much string'
      dummy.anarray.push { 'id': 'gerfewfer/some-file.jpg', 'fileName': 'some-file.jpg' }

      handleSave = (dummy) ->
        return dummy.save (err) ->
          if err
            debug 'Error saving new post: ' + err
            req.flash 'error', 'Post could not be saved.'
          else
            req.flash 'info', 'Post saved.'
          res.redirect app.locals.urls['posts']
          debug 'calling next()'
          return next()

      handleDownload2 = (dummy)->
        debug 'in handleDownload2'
        if req.files.download2
          return dummy.updateff 'download2', req.files.download2, (err)->
            if err
              debug err
              req.flash 'error', 'Post error saving Download 2'
            return handleSave dummy
        return handleSave dummy

      handleDownload1 = (dummy)->
        debug 'in handleDownload1'
        if req.files.download1
          return dummy.updateff 'download1', req.files.download1, (err)->
            if err
              debug err
              req.flash 'error', 'Post error saving Download 1'
            return handleDownload2 dummy
        return handleDownload2 dummy


      handleImages = (dummy) ->
        if req.files.image1 || req.files.image2
          debug 'At least one image was posted'
          return dummy.attachImage req.files.image1, (err) ->
            if err
              debug err
              req.flash 'error', 'Post error saving image 1.'
            #console.log dummy
            if req.files.image2
              return dummy.attachImage req.files.image2, (err) ->
                if err
                  debug err
                  req.flash 'error', 'Post error saving image 2.'
                return handleDownload1(dummy)
            else
              return handleDownload1(dummy)
        else
          debug 'in handleImages'
          return handleDownload1(dummy)

      handleFiles = () ->
        if req.files.file1 || req.files.file2
          debug 'At least one file was posted'
          return dummy.attachFile req.files.file1, (err) ->
            if err
              debug err
              req.flash 'error', 'Post error saving file 1.'
            #console.log dummy
            if req.files.file2
              return dummy.attachFile req.files.file2, (err) ->
                if err
                  debug err
                  req.flash 'error', 'Post error saving file 2.'
                return handleImages(dummy)
            else
              return handleImages(dummy)
        else
          debug 'in handleFiles'
          return handleImages(dummy)

      return handleFiles()
    ,
    upload.cleanUploads()
      

  # The delete form is not multipart, so we need the simpler body-parser module
  # to parse the form fields in the request body.
  app.post app.locals.urls['posts.delete'],
    bodyParser.urlencoded({ extended: false }),
    (req, res, next) ->
      debug 'in posts.delete handler'
      # Find the post by its ID.
      Post.findById req.body.postID, (err, post) ->
        if err
          #console.log 'Post could not be retrieved.'
          req.flash 'error', 'Post could not be retrieved.'
          return res.redirect app.locals.urls['posts']
        else
          debug 'Post retrieved'
          debug post

          if req.body.fileIndex
            # We are deleting an attached file.
            if ! post.files[req.body.fileIndex]
              req.flash 'error', 'Could not find file to delete.'
              return res.redirect app.locals.urls['posts']
            file = post.files[req.body.fileIndex]
            return post.deleteAttachedFile file, (err) ->
              if err
                req.flash 'error', 'File could not be deleted.'
                return res.redirect app.locals.urls['posts']
              else
                return post.save (err, post) ->
                  if err
                    req.flash 'error', 'Post could not be saved.'
                  else
                    req.flash 'info', 'File deleted.'
                    #console.log post
                  return res.redirect app.locals.urls['posts']

          if req.body.imageIndex
            # We are deleting an attached image.
            if ! post.images[req.body.imageIndex]
              req.flash 'error', 'Could not find image to delete.'
              return res.redirect app.locals.urls['posts']
            image = post.images[req.body.imageIndex]
            return post.deleteAttachedImage image, (err) ->
              if err
                req.flash 'error', 'Image could not be deleted.'
                return res.redirect app.locals.urls['posts']
              else
                return post.save (err, post) ->
                  if err
                    req.flash 'error', 'Post could not be saved.'
                  else
                    req.flash 'info', 'Image deleted.'
                    #console.log pos
                  return res.redirect app.locals.urls['posts']

          if req.body.fieldName
            fieldName = req.body.fieldName
            if typeof post[fieldName] != 'object' || typeof post[fieldName].fileName != 'string'
              req.flash 'error', 'No file to delete.'
              return res.redirect app.locals.urls['posts']
            return post.clearff fieldName, (err)->
              if err
                req.flash 'error', 'File could not be deleted.'
                return res.redirect app.locals.urls['posts']
              else
                return post.save (err, post) ->
                  if err
                    req.flash 'error', 'Post could not be saved.'
                  else
                    req.flash 'info', 'File deleted.'
                  return res.redirect app.locals.urls['posts']

          post.remove (err, post) ->
            if err
              #console.log 'Post could not be removed.'
              req.flash 'error', 'Post could not be removed.'
            else
              req.flash 'info', 'Post removed.'
            return res.redirect app.locals.urls['posts']


module.exports =
  assign: assign
