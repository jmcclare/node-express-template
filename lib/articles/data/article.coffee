#
# Model for articles.
#


# Node Packages

mongoose = require 'mongoose'
ObjectId = mongoose.Schema.Types.ObjectId
marked = require 'marked'
jade = require 'jade'

# Our slug generator. See https://github.com/jeremys/uslug
# The best alternative was the slug package. For more on that, see
# https://github.com/dodo/node-slug
uslug = require 'uslug'
# Default is '-_~'. Be a little less restrictive. We also allow a few more via
# word substitutes below.
allowedSlugChars = '-_~.'


# Local Packages
User = require('users').data.User


articleSchema = mongoose.Schema
  title:
    type: String
    required: true
  slug:
    type: String
    required: true
    index:
      unique: true
  description: String
  summary: String
  compiledSummary: String
  body: String
  bodyFormat:
    type: String
    default: 'markdown'
  compiledBody: String
  creationTime: Date
  updateTime: Date
  pubTime: Date
  author:
    type: ObjectId
    ref: 'User'


# This is supposed to get the document's creation time, but it doesn't
# seem to work.
articleSchema.virtual('created')
  .get () ->
    return this._id.generationTime


#
# Set the slug.
#
articleSchema.pre 'validate', true, (next, done) ->
  next()
  article = this

  # Ensure we have a proper slug.
  # Only create a slug if the title has been modified (or is new).
  if article.isModified 'title'
    # Convert the title into a string that can be used as the slug.

    # Do a brief version of what the slug module does and turn some of the
    # special characters into their obvious word replacements.
    slugCharmap = {
      '&': 'and'
      '+': 'plus'
      '%': 'percent'
    }
    slug = ''
    for char in article.title
      if slugCharmap[char]
        char = slugCharmap[char]
      slug += char
    # TODO:
    # * ensure the generated slug is unique
    article.slug = uslug slug, {allowedChars: allowedSlugChars}

  return done()


#
# Set the creation and update times.
#
articleSchema.pre 'validate', true, (next, done) ->
  next()
  article = this

  article.updateTime = Date.now()

  if ! article.creationTime
    article.creationTime = Date.now()

  return done()


#
# Compile the HTML version of the body, `compiledBody`
#
articleSchema.pre 'save', true, (next, done) ->
  next()

  if ! @.body
    @.compiledBody = null
    return done()

  markedOptions =
    gfm: false
    smartypants: true

  switch @.bodyFormat
    when 'markdown'
      # NOTE: You must pass an options array in here or marked will
      # crash the Node process with an unhandled error.
      #marked @.body, markedOptions, (err, content) ->
        #return done err if err
        ##@.compiledBody = content
        #return done()

      # NOTE: If you use the asynchronous version of marked (see above
      # commented code) and try to set @.compiledBody in the callback, it
      # will not be set. This is probably a quirk in how these Mongoose
      # middleware work. At least this middleware runs parallel with the
      # others.
      @.compiledBody = marked @.body, markedOptions
    when 'jade'
      # We can add options and template variables if we want.
      # See: http://jade-lang.com/api/
      fn = jade.compile @.body
      @.compiledBody = fn()
    else
      @.compiledBody = @.body

  return done()


#
# Compile the HTML version of the summary, `compiledSummary`
#
articleSchema.pre 'save', true, (next, done) ->
  next()

  if ! @.summary
    @.compiledSummary = null
    return done()

  markedOptions =
    gfm: false
    smartypants: true

  @.compiledSummary = marked @.summary, markedOptions

  return done()


Article = mongoose.model('Article', articleSchema)


module.exports = Article
