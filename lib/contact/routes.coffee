# 
# Module dependencies.
# 

# npm packages
bodyParser = require 'body-parser'
nodemailer = require("nodemailer")

# local libraries
urls = require 'urls'


#
# Assign our default set of contact routes to the app under parentPath, or the
# default parentPath.
#
assign = (app, parentPath) ->
  parentPath = "/contact"  unless parentPath
  if ! app.locals.urls
    urls.addHelpers app
  #app.locals.urls['contact'] = parentPath + "/"
  app.locals.urls['contact'] = parentPath

  # Factoring this out.
  title = 'Contact Us'
  section = 'contact'
  name = ''
  email = ''
  message = ''
  alertMessages = ''
  errorMessages = ''
  fieldErrors =
    name: ''
    email: ''
    message: ''
  renderForm = (res) ->
    return res.render 'contact',
      title: title
      section: section
      name: name
      email: email
      message: message
      alertMessages: alertMessages
      errorMessages: errorMessages
      fieldErrors: fieldErrors

  app.get app.locals.urls['contact'], (req, res, next) ->
    title = 'Contact Us'
    section = 'contact'
    # Reset these between requests.
    name = ''
    email = ''
    message = ''
    alertMessages = ''
    errorMessages = ''
    fieldErrors =
      name: ''
      email: ''
      message: ''
    return renderForm(res)

  app.post app.locals.urls['contact'],
    bodyParser.urlencoded({extended: false}),
    (req, res, next) ->
      title = 'Contact Us'
      section = 'contact'
      # Reset these between requests.
      name = ''
      email = ''
      message = ''
      alertMessages = ''
      errorMessages = ''
      fieldErrors =
        name: ''
        email: ''
        message: ''

      # Handle user input errors.
      # Tipped off on how to access form data by this page:
      # http://stackoverflow.com/questions/4295782/node-js-extracting-post-data
      #console.log 'Inside contact POST handler'
      #console.log req.body
      if ! req.body.name
        #console.log req.body.name
        fieldErrors['name'] = 'Please fill in your name.'
      # Regular expression comes from Stack Overflow:
      # http://stackoverflow.com/questions/46155/validate-email-address-in-javascript
      re = /[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/
      if ! re.test(req.body.email)
        fieldErrors['email'] = 'Please fill in a valid email address.'
      if ! req.body.message
        fieldErrors['message'] = 'Please fill in a valid message.'
      if errorMessages
        return renderForm(res)
      for type,error of fieldErrors
        if error
          name = req.body.name
          email = req.body.email
          message = req.body.message
          return renderForm(res)

      transport = nodemailer.createTransport "sendmail"
      mailOptions =
        replyTo: req.body.name + '<' + req.body.email + '>'
        text: req.body.name + " (" + req.body.email + ") sent the following message using the site contact form:\n\n" + req.body.message

      # Merge the app's mail options
      keys = Object.keys app.set 'contactMailOptions'
      for key in keys
        if (!mailOptions.hasOwnProperty(key))
          mailOptions[key] = app.set('contactMailOptions')[key]

      if ! mailOptions['subject']
        mailOptions['subject'] = "Message from site contact form"

      # TODO: factor out the res.render calls
      # Make sure the hidden 'url' honeypot field was not filled in. iIf it was,
      # it must have been either a spam bot or somebody hacking around. Either
      # way, act like the message was sent successfully, but don't actually send
      # it.
      if req.body.url
        req.flash 'info', 'Message sent.'
        res.redirect app.locals.urls['contact']
      else
        transport.sendMail mailOptions, (error, response) ->
          if (error)
            console.log error
            errorMessages = 'Sorry, there was an internal error. Your message could not be sent. Please try again later.'
            return renderForm(res)
          else
            console.log '[MAIL SENT]', JSON.stringify mailOptions
            req.flash 'info', 'Message sent.'
            res.redirect app.locals.urls['contact']

          # We don't want to use this transport object anymore.
          transport.close() # shut down the connection pool, no more messages

module.exports =
  assign: assign
