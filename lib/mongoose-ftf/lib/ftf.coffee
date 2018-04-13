# Standard packages


# Node packages

marked = require 'marked'
jade = require 'jade'
async = require 'async'


plugin = (schema, options) ->
  fieldName = 'body'
  fieldName = options.fieldName if options.fieldName

  defaultFormat = 'markdown'
  defaultformat = options.defaultformat if options.defaultformat

  required = false
  required = options.required if options.required

  ftags = true
  ftags = options.ftags if typeof options.ftags == 'boolean'

  itags = true
  itags = options.itags if typeof options.itags == 'boolean'

  schemaAdditions = {}

  schemaAdditions[fieldName] =
    base:
      type: String
      required: required
    format:
      type: String
      required: false
      default: defaultFormat
    compiled:
      type: String
      required: false

  schema.add schemaAdditions


  #
  # Compile the formatted version of the `base` and store it in `compiled`.
  #
  schema.pre 'save', true, (next, done) ->
    instance = this
    next()

    # If there is no base text, set the compiled text to blank and return.
    if ! instance[fieldName].base
      instance[fieldName].compiled = ''
      return done()

    compiled = instance[fieldName].base

    # Check the ftags option and check for the method and array
    # mongoose-file-attachements adds to make sure we have attached files.
    if ftags && instance.attachedFileURL && typeof instance.files != 'undefined'
      # Replace all tags of the form #{furl:3} with the appropriate attached
      # file URL.
      # For more on JavaScript regular expressions, see:
      # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp
      re = /(^|[^\\]{1,1})#{furl:([0-9]+)}/g
      compiled = compiled.replace re, (match, p1, p2, offset, string) ->
        if instance.files[p2]
          return p1 + instance.attachedFileURL instance.files[p2]
        else
          # Clear tags that refer to non-existent files
          return ''

    # Check the itags option and check for the method and array
    # mongoose-image-attachements adds to make sure we have attached files.
    if itags && instance.attachedImageURL && typeof instance.images != 'undefined'
      # Replace all tags of the form #{iurl:3} with the appropriate attached
      # image file URL.
      # For more on JavaScript regular expressions, see:
      # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp
      re = /(^|[^\\]{1,1})#{iurl:([0-9]+)}/g
      compiled = compiled.replace re, (match, p1, p2, offset, string) ->
        if instance.images[p2]
          return p1 + instance.attachedImageURL instance.images[p2]
        else
          # Clear tags that refer to non-existent images
          return ''

      # Replace all tags of the form #{iurl:2:thumbnail} with the appropriate
      # attached image file URL.
      # For more on JavaScript regular expressions, see:
      # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp
      re = /(^|[^\\]{1,1})#{iurl:([0-9]+):([ 0-9a-zA-Z_-]+)}/g
      compiled = compiled.replace re, (match, p1, p2, p3, offset, string) ->
        if instance.images[p2]
          return p1 + instance.attachedImageURL instance.images[p2], p3
        else
          # Clear tags that refer to non-existent images
          return ''

    #
    # To have a properly formatted tag show up in your text without being
    # parsed and replaced, prefix it with a backslash, ie. \#{furl:1}
    #
    # This function removes the leading backslash from all of these tags.
    #
    unescapeTags = (text) ->
      re = /(^|[^\\]{1,1})(#{*?})/g
      return text.replace re, '$2'

    switch instance[fieldName].format
      when 'markdown'
        compiled = unescapeTags compiled
        # NOTE: You must pass an options object in here or marked will
        # crash the Node process with an unhandled error.
        markedOptions =
          gfm: false
          smartypants: true
        return marked compiled, markedOptions, (err, html) ->
          return done err if err
          instance[fieldName].compiled = html
          return done()
      when 'jade'
        # We can add options and template variables if we want.
        # See: http://jade-lang.com/api/
        return jade.render compiled, {}, (err, html) ->
          return done err if err
          instance[fieldName].compiled = html
          return done()
      else
        compiled = unescapeTags compiled
        instance[fieldName].compiled = compiled

    return done()


module.exports = plugin
