path = require 'path'
fs = require 'fs.extra'
util = require 'util'

require('chai').should()
# Use chai's assert, not node.js' included assert
assert = require('chai').assert

uuid = require 'uuid'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
gm = require 'gm'


# local packages

tools = require 'tools'


existsFn = fs.exists || path.exists
existsSync = fs.existsSync || path.existsSync


describe 'module', () ->
  it 'should create a global instance of itself', () ->
    imageStore = require 'image-store'
    imageStore.setOption 'foo2', 5
    imageStore2 = require 'image-store'
    imageStore2.getOption('foo2').should.equal 5

  it 'should provide a FileMissingError class', () ->
    FileMissingError = require('file-store').Error.FileMissingError
    fmerror = new FileMissingError()
    fmerror.name.should.equal 'FileMissingError'
    assert.ok fmerror.message, 'No message property for FileMissingError class.'
    assert fmerror.toString() == 'FileMissingError: File does not exist.'
    fmerror = new FileMissingError('Some message about this error.')
    assert fmerror.toString() == 'FileMissingError: Some message about this error.'


describe 'ImageStore', () ->
  # We were getting timeouts from the beforeEach and afterEach functions with
  # the default 2000ms timeout because there are a lot of disk operations
  # happening at once.
  @timeout 5000

  # Each test will get its own instance of this variable to play with. The
  # beforeEach function will set different uuids and create different
  # directories for each test.
  testOptions = {}

  beforeEach (done) ->
    # Set the test parameters.
    testOptions = {}
    testOptions.fileStoreOptions = {}
    testOptions.fileStoreOptions.publicDir = '/tmp/' + uuid.v4()
    testOptions.fileStoreOptions.fileDataDir = '_dynamic'
    testOptions.fileStoreOptions.collection = 'blob'
    testOptions.fileStoreOptions.subCollection = ''

    # Create the publicDir
    oldMask = process.umask 0o000
    mkdirp testOptions.fileStoreOptions.publicDir, 0o775, (err) ->
      assert(false, err) if err
      process.umask oldMask

      # Set some options just for the tests. These should have no effect on the
      # ImageStore object.
      testOptions.sampleDataDir = '/tmp/' + uuid.v4()
      # Create the sampleDataDir
      oldMask = process.umask 0o000
      mkdirp testOptions.sampleDataDir, 0o775, (err) ->
        assert(false, err) if err
        process.umask oldMask

        dummy1Path = path.join(__dirname, 'sample-files/large-hollow-island.jpg')
        tempDummy1Path = path.join(testOptions.sampleDataDir, 'large-hollow-island.jpg')
        testOptions.tempDummy1Path = tempDummy1Path

        dummy2Path = path.join(__dirname, 'sample-files/mount-kilimanjaro.jpg')
        tempDummy2Path = path.join(testOptions.sampleDataDir, 'mount-kilimanjaro.jpg')
        testOptions.tempDummy2Path = tempDummy2Path

        tarFilePath = path.join(__dirname, 'sample-files/a-file.txt.tar.gz')
        tempTarFilePath = path.join(testOptions.sampleDataDir, 'a-file.txt.tar.gz')
        testOptions.tempTarFilePath = tempTarFilePath

        fs.copy dummy1Path, tempDummy1Path, (err) ->
          assert false, err.toString() if err
          fs.copy dummy2Path, tempDummy2Path, (err) ->
            assert false, err.toString() if err
            fs.copy tarFilePath, tempTarFilePath, (err) ->
              assert false, err.toString() if err
              done()

  afterEach (done) ->
    # Delete the publicDir and sampleDataDir
    rimraf testOptions.fileStoreOptions.publicDir, (err1) ->
      rimraf testOptions.sampleDataDir, (err2) ->
        assert(false, err1) if err1
        assert(false, err2) if err2
        done()

  describe 'options()', ->
    it 'should return the full options object', () ->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore()
      imageStore2.setOption 'dummy', 'some string'
      imageStore2.options (err, options)->
        assert(false, err) if err
        options['dummy'].should.equal 'some string'

    it 'should merge supplied options into its own', () ->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore()
      imageStore2.setOption 'dummy', 'some string'
      imageStore2.options { anOption: 'an option string' }, (err, options)->
        assert false, err if err
        imageStore2.optionsSync().anOption.should.equal 'an option string'
        imageStore2.optionsSync()['dummy'].should.equal 'some string'

    it 'should reset options to defaults', ()->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore()

      imageStore2.setOption 'fileStoreOptions', { collection: 'not-image' }
      imageStore2.setOption 'dummy8', 'some other string'
      imageStore2.optionsSync { anotherOption: 'another option string' }

      imageStore2.resetOptions (err, options)->
        assert false, err if err

        assert typeof imageStore2.optionsSync().fileStoreOptions.collection == 'string'
        assert.notOk imageStore2.optionsSync()['dummy8']
        assert.notOk imageStore2.optionsSync()['anotherOption']

    it 'should reset options and merge the supplied object', ()->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore()

      imageStore2.setOption 'fileStoreOptions', { collection: 'not-image' }
      imageStore2.setOption 'dummy8', 'some other string'

      newOptions =
        option1: 'some value'
        option2: 'some other value'
        collection: 'some-random-collection-name-lsat23oifbw398iv'

      imageStore2.resetOptions newOptions, (err, options)->

        assert typeof imageStore2.optionsSync().fileStoreOptions.collection == 'string'
        imageStore2.optionsSync()['collection'].should.equal 'some-random-collection-name-lsat23oifbw398iv'
        assert.notOk imageStore2.optionsSync()['dummy8']
        assert.notOk imageStore2.optionsSync()['anotherOption']

    it 'replaces formats with what is passed in', (done)->
      imageStore = require 'image-store'

      embeddedFormat =
        formats:
          embedded:
            width: 500
            height: 300
      blankFormats =
        formats: {}

      imageStore2 = new imageStore.ImageStore embeddedFormat
      imageStore2.options blankFormats, (err, options)->
        if err
          assert false,
            'Error returned by ImageStore.options(): ' + err.toString()
        type = typeof imageStore2.getOption('formats')['embedded']
        type.should.equal 'undefined'
        done()

    it 'replaces gmOptions with what is passed in', (done)->
      imageStore = require 'image-store'

      standardGM =
        gmOptions:
          imageMagick: true
      blankGM =
        gmOptions: {}

      imageStore2 = new imageStore.ImageStore standardGM

      imageStore2.options blankGM, (err, options)->
        if err
          assert false,
            'Error returned by ImageStore.options(): ' + err.toString()
        type = typeof imageStore2.getOption('gmOptions')['imageMagick']
        type.should.equal 'undefined'
        done()

    it 'replaces fileStoreOptions with what is passed in', (done)->
      imageStore = require 'image-store'

      standardGM =
        gmOptions:
          imageMagick: true
      blankGM =
        gmOptions: {}

      imageStore2 = new imageStore.ImageStore standardGM

      imageStore2.options blankGM, (err, options)->
        if err
          assert false,
            'Error returned by ImageStore.options(): ' + err.toString()
        type = typeof imageStore2.getOption('gmOptions')['imageMagick']
        type.should.equal 'undefined'
        done()

    it 'returns an error if fileType option is invalid', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      formats =
        embedded:
          width: 114
          height: 87
          fileType: 'somethingimadeupthatisdefinitelynotavalidformet'
      imageStore2.options { formats: formats }, (err, storedOps)->
        if ! err
          assert false,
            'No error returned for invalid fileType option.'
        err.toString().should.equal 'Error: Unsupported fileType option for embedded format.',
          'Wrong error message for invalid fileType option.'
        done()

    it 'returns an error if resizeType option is invalid', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      formats =
        embedded:
          width: 114
          height: 87
          resizeType: 'jhnd7d6b57s67HH'
      imageStore2.options { formats: formats }, (err, storedOps)->
        if ! err
          assert false,
            'No error returned for invalid resizeType option.'
        err.toString().should.equal 'Error: Unsupported resizeType for embedded format.',
          'Wrong error message for invalid resizeType option.'
        done()

  describe 'setOption()', ->
    it 'sets the specified option', ()->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore()
      description = 'The most compelling description ever written.'
      try
        imageStore2.setOption 'description', description
      catch err
        assert false, 'Error thrown setting valid option: ' + err.toString()
      assert.equal imageStore2.getOption('description'), description,
        'option not set to specified value.'

    it 'throws an error for invalid option', ()->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore()
      try
        imageStore2.setOption 'description', 42
      catch err
        assert.equal err.toString(),
          'TypeError: options.description must be a string.'
        errThrown = true
      if ! errThrown
        assert false, 'No error thrown for invalid option.'

  describe 'optionsSync()', ->
    it 'should set and return options', () ->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore()
      imageStore2.setOption 'foo', 5
      imageStore2.getOption('foo').should.equal 5

    it 'should return the full options object', () ->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore()
      imageStore2.setOption 'dummy', 'some string'
      imageStore2.optionsSync()['dummy'].should.equal 'some string'

    it 'should merge supplied options into its own', () ->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore()
      imageStore2.setOption 'dummy', 'some string'
      imageStore2.optionsSync { anOption: 'an option string' }
      imageStore2.optionsSync().anOption.should.equal 'an option string'
      imageStore2.optionsSync()['dummy'].should.equal 'some string'

    it 'throws an error for invalid option', () ->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore()
      imageStore2.setOption 'dummy', 'some string'
      # Use an integer instead of a string for description
      errThrown = false
      try
        imageStore2.optionsSync { description: 42 }
      catch err
        assert.equal err.toString(),
          'TypeError: options.description must be a string.'
        errThrown = true
      if ! errThrown
        assert false, 'No error thrown for invalid option.'

    it 'should reset options to defaults', ()->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore()

      imageStore2.setOption 'fileStoreOptions', { collection: 'not-image' }
      imageStore2.setOption 'dummy8', 'some other string'
      imageStore2.optionsSync { anotherOption: 'another option string' }

      imageStore2.resetOptionsSync()

      assert typeof imageStore2.optionsSync().fileStoreOptions.collection == 'string'
      assert.notOk imageStore2.optionsSync()['dummy8']
      assert.notOk imageStore2.optionsSync()['anotherOption']

    it 'should reset options and merge the supplied object', ()->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore()

      imageStore2.setOption 'fileStoreOptions', { collection: 'not-image' }
      imageStore2.setOption 'dummy8', 'some other string'

      newOptions =
        option1: 'some value'
        option2: 'some other value'
        collection: 'some-random-collection-name-lsat23oifbw398iv'

      imageStore2.resetOptionsSync(newOptions)

      assert typeof imageStore2.optionsSync().fileStoreOptions.collection == 'string'
      imageStore2.optionsSync()['collection'].should.equal 'some-random-collection-name-lsat23oifbw398iv'
      assert.notOk imageStore2.optionsSync()['dummy8']
      assert.notOk imageStore2.optionsSync()['anotherOption']

    it 'replaces formats with what is passed in', (done)->
      imageStore = require 'image-store'

      embeddedFormat =
        formats:
          embedded:
            width: 500
            height: 300
      blankFormats =
        formats: {}

      imageStore2 = new imageStore.ImageStore embeddedFormat
      try
        imageStore2.optionsSync blankFormats
      catch err
        assert false,
          'Error returned by ImageStore.options(): ' + err.toString()
      type = typeof imageStore2.getOption('formats')['embedded']
      type.should.equal 'undefined'
      done()

    it 'replaces gmOptions with what is passed in', (done)->
      imageStore = require 'image-store'

      standardGM =
        gmOptions:
          imageMagick: true
      blankGM =
        gmOptions: {}

      imageStore2 = new imageStore.ImageStore standardGM
      try
        imageStore2.optionsSync blankGM
      catch err
        assert false,
          'Error returned by ImageStore.options(): ' + err.toString()
      type = typeof imageStore2.getOption('gmOptions')['imageMagick']
      type.should.equal 'undefined'
      done()

    it 'replaces fileStoreOptions with what is passed in', (done)->
      imageStore = require 'image-store'

      standardFSO =
        fileStoreOptions:
          collection: 'image'
      blankFSO =
        fileStoreOptions: {}

      imageStore2 = new imageStore.ImageStore standardFSO
      try
        imageStore2.optionsSync blankFSO
      catch err
        assert false,
          'Error returned by ImageStore.options(): ' + err.toString()
      type = typeof imageStore2.getOption('fileStoreOptions')['collection']
      type.should.equal 'undefined'
      done()

  describe 'constructor', ->
    it 'should create a new instance of ImageStore', () ->
      imageStore = require 'image-store'
      imageStore.setOption 'foo34543534', 565559
      imageStore2 = new imageStore.ImageStore()
      assert.isUndefined imageStore2.getOption('foo34543534'), 'unset option foo3 should be undefined'
      imageStore2.setOption 'foo34543534', 6
      imageStore.getOption('foo34543534').should.equal 565559, 'option not at proper set value'
      imageStore2.getOption('foo34543534').should.equal 6, 'option not at proper set value'

    it 'should set options supplied to constructor', ->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore { anOption: 'an option string' }
      imageStore2.optionsSync().anOption.should.equal 'an option string'

      # Test some nested options
      options2 =
        someOption: 'something I made up'
        fileStoreOptions:
          publicDir: '/tmp/some-dir'
      imageStore3 = new imageStore.ImageStore options2
      imageStore3.optionsSync().fileStoreOptions.publicDir.should.equal '/tmp/some-dir'

    it 'should set default options', ->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore()

      assert typeof imageStore2.optionsSync().formats.embedded.width == 'number',
        'default embedded format not set'
      assert typeof imageStore2.optionsSync().formats.thumbnail.width == 'number',
        'default thumbnail format not set'
      assert typeof imageStore2.optionsSync().fileStoreOptions.collection == 'string',
        'default fileStoreOptions.collection not set'

  describe 'store()', ->
    it 'should return an error if source file does not exist', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions
      imageStore2.store '/non/existant.jpg', (err, image) ->
        fileStore = require 'file-store'
        if ! err
          assert false, 'No Error returned for non-existant source file.'
        if ! err instanceof fileStore.Error.FileMissingError
          assert false, 'Wrong class of error returned.'
        err.name.should.equal 'FileMissingError', 'Wrong class of error returned.'
        done()

    it 'should take an optional options object parameter', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      # Tell imageStore to store this sample image with a blank options object.
      options = {}
      imageStore2.store testOptions.tempDummy1Path, options, (err, image) ->
        if err
          assert false,
            'Error returned by ImageStore.store(): ' + err.toString()

        done()

    it 'should pass an error when options is not an object', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      # Tell imageStore to store this sample image with a string for options.
      imageStore2.store testOptions.tempDummy1Path, 'a string', (err, image) ->
        if ! err
          assert false,
            'No error returned by ImageStore.store() for invalid options type'
        err.toString().should.equal "TypeError: options must be an object."
        done()

    it 'should pass an error when options is a Date', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      # Tell ImageStore to store this sample image with a Date object for
      # options.
      options = new Date()
      imageStore2.store testOptions.tempDummy1Path, options, (err, image) ->
        if ! err
          assert false,
            'No error returned by ImageStore.store() for invalid options type'
        err.toString().should.equal "TypeError: options cannot be a Date object."
        done()

    it 'should pass an error when options is an Array', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      # Tell ImageStore to store this sample image with a Array for options.
      options = ['one', 'two', 'three']
      imageStore2.store testOptions.tempDummy1Path, options, (err, image) ->
        if ! err
          assert false,
            'No error returned by ImageStore.store() for invalid options type'
        err.toString().should.equal "TypeError: options cannot be an Array."
        done()

    it "completely replaces stored format options with what's supplied", (done)->
      imageStore = require 'image-store'

      embeddedFormat =
        formats:
          embedded:
            width: 500
            height: 300
      blankFormats =
        formats: {}

      imageStore2 = new imageStore.ImageStore testOptions
      imageStore2.options embeddedFormat, (err, options) ->
        imageStore2.optionsSync().formats.embedded.width.should.equal 500

        imageStore2.store testOptions.tempDummy1Path, blankFormats, (err, image) ->
          if err
            assert false,
              'Error returned by ImageStore.store(): ' + err.toString()

          # Make sure there is no pubPath for the embedded format.
          try
            pubPath = imageStore2.pubPath image, format: 'embedded'
          catch err
            assert 'ReferenceError: format does not exist.', err.toString()
            return done()
          assert false, 'No error returned for format that should not exist.'
          done()

    it 'takes a name option', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      # Tell imageStore to store this sample image with a blank options object.
      options = {
        name: 'my favourite tree'
      }
      imageStore2.store testOptions.tempDummy1Path, options, (err, image) ->
        if err
          assert false,
            'Error returned by ImageStore.store(): ' + err.toString()
        image.name.should.equal 'my favourite tree'

        done()

    it 'defaults name to file.name when blank', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      # Tell imageStore to store this sample image with a blank options object.
      options = {}
      imageStore2.store testOptions.tempDummy1Path, options, (err, image) ->
        if err
          assert false,
            'Error returned by ImageStore.store(): ' + err.toString()
        image.name.should.equal image.formats.original.file.name

        done()

    it 'takes a description option', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      # Tell imageStore to store this sample image with a blank options object.
      options = {
        description: 'sailboat at the dock'
        fileStoreOptions:
          description: 'sailboat docked'
          publicDir: testOptions.fileStoreOptions.publicDir
      }
      imageStore2.store testOptions.tempDummy1Path, options, (err, image) ->
        if err
          assert false,
            'Error returned by ImageStore.store(): ' + err.toString()
        image.description.should.equal 'sailboat at the dock'

        done()

    it 'should store original file', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      imageStore2.store testOptions.tempDummy1Path, (err, image) ->
        if err
          assert false,
            'Error returned by ImageStore.store(): ' + err.toString()

        # Check to see if the original file has been stored where it should be.
        pubPath = imageStore2.pubPath image
        fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
        existsFn fPath, (exists)->
          assert exists, 'Cannot find stored original image file.'
          done()

    it 'should store original file with no format options', (done)->
      # Make a set of options with only the fileStoreOptions and definitely no
      # formats defined.
      tools.clone testOptions.fileStoreOptions, (err, fileStoreOptions)->
        testOptions2 =
          fileStoreOptions: fileStoreOptions

        imageStore = require 'image-store'
        imageStore2 = new imageStore.ImageStore testOptions2

        imageStore2.store testOptions.tempDummy1Path, (err, image) ->
          if err
            assert false,
              'Error returned by ImageStore.store(): ' + err.toString()

          # Check to see if the original file has been stored where it should be.
          pubPath = imageStore2.pubPath image
          fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
          existsFn fPath, (exists)->
            assert exists, 'Cannot find stored original image file.'
            done()

    it 'should store original file with empty format options', (done)->
      # Make a set of options with only the fileStoreOptions and formats set to
      # an empty object.
      tools.clone testOptions.fileStoreOptions, (err, fileStoreOptions)->
        testOptions2 =
          formats: {}
          fileStoreOptions: fileStoreOptions

        imageStore = require 'image-store'
        imageStore2 = new imageStore.ImageStore testOptions2

        imageStore2.store testOptions.tempDummy1Path, (err, image) ->
          if err
            assert false,
              'Error returned by ImageStore.store(): ' + err.toString()

          # Check to see if the original file has been stored where it should be.
          pubPath = imageStore2.pubPath image
          fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
          existsFn fPath, (exists)->
            assert exists, 'Cannot find stored original image file.'
            done()

    it 'should store original file after setting empty format options', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions
      # Set formats to an empty object
      imageStore2.options { formats: {} }, (err, storedOps)->
        assert.notOk storedOps.formats.original

        imageStore2.store testOptions.tempDummy1Path, (err, image) ->
          if err
            assert false,
              'Error returned by ImageStore.store(): ' + err.toString()

          # Check to see if the original file has been stored where it should be.
          pubPath = imageStore2.pubPath image
          fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
          existsFn fPath, (exists)->
            assert exists, 'Cannot find stored original image file.'
            done()

    # Test sending a .tar.gz file.
    # It should return an error
    it 'returns an error for unsupported file format', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      imageStore2.store testOptions.tempTarFilePath, (err, image) ->
        if ! err
          assert false,
            'No error returned by ImageStore.store() for bad file format.'
        assert err.toString(), 'Error: Unsupported file format.'
        done()

    it 'should store all image formats', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      formats =
        embedded:
          width: 400
        thumbnail:
          width:  50
          height: 80
      imageStore2.options { formats: formats }, (err, storedOps)->
        imageStore2.store testOptions.tempDummy1Path, (err, image) ->
          if err
            assert false,
              'Error returned by ImageStore.store(): ' + err.toString()

          # Check to see if the original file has been stored where it should be.
          pubPath = imageStore2.pubPath image, { format: 'thumbnail' }
          fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
          existsFn fPath, (exists)->
            assert exists, 'Cannot find stored thumbnail format image file.'

            # Check to see if the embedded version has been stored where it
            # should be
            pubPath = imageStore2.pubPath image, { format: 'embedded' }
            fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
            existsFn fPath, (exists)->
              assert exists, 'Cannot find stored embedded format image file.'

              # Check to see if the original version has been stored where it
              # should be
              pubPath = imageStore2.pubPath image
              fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
              existsFn fPath, (exists)->
                assert exists, 'Cannot find stored original format image file.'
              
                done()

    it 'fits the image within dimensions specified', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      formats =
        embedded:
          width: 114
          height: 87
          #resizeType: 'force'
      imageStore2.options { formats: formats }, (err, storedOps)->
        if err
          assert false,
              'Error returned by ImageStore.options(): ' + err.toString()
        imageStore2.store testOptions.tempDummy1Path, (err, image) ->
          if err
            assert false,
              'Error returned by ImageStore.store(): ' + err.toString()

          # Check to see if the original file has been stored where it should be.
          pubPath = imageStore2.pubPath image
          fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
          existsFn fPath, (exists)->
            assert exists, 'Cannot find stored original image file.'

            # Check to see if the embedded version has beed stored where it
            # should be
            pubPath = imageStore2.pubPath image, { format: 'embedded' }
            fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
            gm(fPath).options(imageStore2.optionsSync().gmOptions).size (err, size)->
              if err
                assert false, 'gm returned an error reading size of new image file.'
              assert size.width <= 114, 'Size is larger than specified.'
              assert size.height <= 87, 'Size is larger than soecified.'
              done()

    it 'stores a formatted original if specified', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      formats =
        original:
          width: 400
          height: 600
          resizeType: 'force'
        embedded:
          width: 80
          height: 50
          resizeType: 'force'
      imageStore2.options { formats: formats }, (err, storedOps)->
        imageStore2.store testOptions.tempDummy1Path, (err, image) ->
          if err
            assert false,
              'Error returned by ImageStore.store(): ' + err.toString()

          # Check to see if the original file has been stored where it should be.
          pubPath = imageStore2.pubPath image
          fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
          existsFn fPath, (exists)->
            assert exists, 'Cannot find stored original image file.'

            # Check the size of the stored original image.
            gm(fPath).options(imageStore2.optionsSync().gmOptions).size (err, size)->
              if err
                assert false, 'gm returned an error reading size of new image file.'
              assert size.width <= 400, 'Image width is larger than specified.'
              assert size.height <= 600, 'Image height is larger than soecified.'
              done()

    it 'resizes the image to exact dimensions specified', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      formats =
        embedded:
          width: 114
          height: 87
          resizeType: 'force'
      imageStore2.options { formats: formats }, (err, storedOps)->
        imageStore2.store testOptions.tempDummy1Path, (err, image) ->
          if err
            assert false,
              'Error returned by ImageStore.store(): ' + err.toString()

          # Check to see if the original file has been stored where it should be.
          pubPath = imageStore2.pubPath image
          fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
          existsFn fPath, (exists)->
            assert exists, 'Cannot find stored original image file.'

            # Check to see if the embedded version has beed stored where it
            # should be
            pubPath = imageStore2.pubPath image, { format: 'embedded' }
            fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
            gm(fPath).options(imageStore2.optionsSync().gmOptions).size (err, size)->
              if err
                assert false, 'gm returned an error reading size of new image file.'
              size.width.should.equal 114
              size.height.should.equal 87
              done()

    it 'stores fileStoreOptions in the image object', (done)->
      imageStore = require 'image-store'

      tools.clone testOptions, (err, options)->
        # Set one of the fileStoreOptions to a unique name to ensure the one we
        # set is stored.
        options.fileStoreOptions.fileDataDir = 'some-name-34t28098nwergg54'

        imageStore2 = new imageStore.ImageStore options

        imageStore2.store testOptions.tempDummy1Path, (err, image) ->
          if err
            assert false,
              'Error returned by ImageStore.store(): ' + err.toString()

          assert image.fileStoreOptions.fileDataDir == 'some-name-34t28098nwergg54',
            'image fileStoreOptions did not match what was set.'

          # Check to see if the original file has been stored where it should be.
          pubPath = imageStore2.pubPath image
          fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
          existsFn fPath, (exists)->
            assert exists, 'Cannot find stored original image file.'
            done()

    it 'stores options in image and uses them in pubpath and delete', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      tools.clone testOptions, (err, options)->
        # Set one of the fileStoreOptions to a unique name to ensure the one we
        # set it stored.
        options.fileStoreOptions.fileDataDir = 'some-name-34t808nwegg54'

        imageStore2.store testOptions.tempDummy1Path, options, (err, image) ->
          if err
            assert false,
              'Error returned by ImageStore.store(): ' + err.toString()

          assert image.fileStoreOptions.fileDataDir == 'some-name-34t808nwegg54',
            'image fileStoreOptions did not match what was set.'

          # Check to see if the original file has been stored where it should be.
          pubPath = imageStore2.pubPath image
          fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
          existsFn fPath, (exists)->
            assert exists, 'Cannot find stored original image file.'

            imageStore2.delete image, (err)->
              if err
                assert false,
                  'Error returned by ImageStore.delete(): ' + err.toString()

              done()

    it 'saves formats in specified fileType', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      formats =
        embedded:
          width: 114
          height: 87
          fileType: 'PNG'
      imageStore2.options { formats: formats }, (err, storedOps)->
        imageStore2.store testOptions.tempDummy1Path, (err, image) ->
          if err
            assert false,
              'Error returned by ImageStore.store(): ' + err.toString()

          # Check to see if the original file has been stored where it should be.
          pubPath = imageStore2.pubPath image
          fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
          existsFn fPath, (exists)->
            assert exists, 'Cannot find stored original image file.'

            # Check to see if the embedded version has beed stored where it
            # should be
            pubPath = imageStore2.pubPath image, { format: 'embedded' }
            fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
            gm(fPath).options(imageStore2.optionsSync().gmOptions).format (err, format)->
              if err
                assert false, 'gm returned an error reading format of new image file.'
              assert format == formats.embedded.fileType, 'Image stored in wrong fileType.'
              done()

    it 'returns an error if fileType option is invalid', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      storeOptions =
        formats:
          embedded:
            width: 114
            height: 87
            fileType: 'somethingimadeupthatisdefinitelynotavalidformet'
      imageStore2.store testOptions.tempDummy1Path, storeOptions, (err, image) ->
        if ! err
          assert false,
            'No error returned for invalid fileType option.'
        err.toString().should.equal 'Error: Unsupported fileType option for embedded format.',
          'Wrong error message for invalid fileType option.'
        done()

    it 'messing with gm', (done)->
      #gm = require 'gm'
      #gm(
        ##'/home/jmcclare/Downloads/upload/sample-images/The_Gentle_Giant_by_ChewedKandi.png'
        ##'/home/jmcclare/Downloads/upload/sample-images/smiley.png'
        ##'/home/jmcclare/Downloads/upload/sample-images/woman-on-manhattan-balcony.jpg'
        ##'/home/jmcclare/Downloads/upload/sample-images/large-hollow-island.jpg'
        ##'/home/jmcclare/Downloads/upload/sample-images/blue-ball-fixed.gif'
        ##'/home/jmcclare/Downloads/upload/sample-images/runner-inlaid.bmp'
        ##'/home/jmcclare/Downloads/upload/sample-images/smiley.tiff'
        #'/home/jmcclare/Downloads/upload/sample-images/full-design-03-print.svg'
      #).options({imageMagick: true}).format (err, format)->
        ##console.log 'format: ' + format + '  ...'
        #done()

      done()

  describe 'pubPath()', ->
    it 'should give a public path based on an image object', (done) ->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions
      # Tell ImageStore to store a sample file.
      imageStore2.store testOptions.tempDummy1Path, (err, image) ->
        pubPath = imageStore2.pubPath image
        assert.ok pubPath, 'returned pubPath is empty or null'
        assert typeof pubPath == 'string', 'returned pubPath is not a string'
        fullPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
        existsFn fullPath, (exists) ->
          if !exists
            assert false, 'pubPath did not point to original image file.'
          done()

    it 'should take an optional options object parameter', (done) ->
      imageStore = require 'image-store'
      tools.clone testOptions, (err, localOptions)->
        # Ensure we have `embedded` and `thumbnail` formats.
        localOptions.formats =
          embedded:
            width: 400
          thumbnail:
            width: 80
            height: 50
        imageStore2 = new imageStore.ImageStore localOptions

        imageStore2.store testOptions.tempDummy1Path, (err, image) ->
          pubPathOptions =
            fileStoreOptions:
              fileDataDir: '/tmp/some-other-dir-sgejnd43f43f' 
          pubPath = imageStore2.pubPath image, pubPathOptions
          assert.ok pubPath, 'returned pubPath is empty or null'
          re = /\/tmp\/some-other-dir-sgejnd43f43f/
          assert re.test(pubPath), 'returned pubPath does not contain fileDataDir.'
          done()

    it 'should throw an error when options is not an object', (done) ->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      imageStore2.store testOptions.tempDummy1Path, (err, image) ->
        pubPathOptions = 'a string'
        try
          pubPath = imageStore2.pubPath image, pubPathOptions
        catch err
          caught = true
          assert err instanceof TypeError
        assert caught, 'No error thrown for invalid options object.'
        done()

    it 'should throw an error when image does not contain format', (done) ->
      imageStore = require 'image-store'
      tools.clone testOptions, (err, localOptions)->
        # Ensure we have `embedded` and `thumbnail` formats.
        localOptions.formats =
          embedded:
            width: 400
          thumbnail:
            width: 80
            height: 50
        imageStore2 = new imageStore.ImageStore localOptions

        imageStore2.store testOptions.tempDummy1Path, (err, image) ->
          pubPathOptions =
            format: 'something-invalid'
          try
            pubPath = imageStore2.pubPath image, pubPathOptions
          catch err
            caught = true
            assert err instanceof ReferenceError
          assert caught, 'No error thrown for invalid format.'
          done()

  describe 'delete()', ->
    it 'takes an image object and deletes the associated image files', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      formats =
        embedded:
          width: 400
        thumbnail:
          width:  50
          height: 80
      imageStore2.options { formats: formats }, (err, storedOps)->
        imageStore2.store testOptions.tempDummy1Path, (err, image) ->
          if err
            assert false,
              'Error returned by ImageStore.store(): ' + err.toString()

          # Check to see if the original file has been stored where it should be.
          pubPath = imageStore2.pubPath image
          fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
          existsFn fPath, (exists)->
            assert exists, 'Original image file not stored.'

            # Check to see if the embedded version has been stored where it
            # should be
            pubPath = imageStore2.pubPath image, { format: 'embedded' }
            fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
            existsFn fPath, (exists)->
              assert exists, 'embedded format image file not stored.'

              # Check to see if the original version has been stored where it
              # should be
              pubPath = imageStore2.pubPath image, { format: 'thumbnail' }
              fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
              existsFn fPath, (exists)->
                assert exists, 'thumbnail format image file not stored.'

                imageStore2.delete image, (err)->
                  if err
                    assert false,
                      'Error returned by ImageStore.delete(): ' + err.toString()

                  # Check to see if the original file has been deleted.
                  pubPath = imageStore2.pubPath image
                  fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
                  existsFn fPath, (exists)->
                    assert ! exists, 'Original image file not deleted.'

                    # Check to see if the embedded version has been deleted.
                    pubPath = imageStore2.pubPath image, { format: 'embedded' }
                    fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
                    existsFn fPath, (exists)->
                      assert ! exists, 'embedded format image file not deleted.'

                      # Check to see if the original version has been deleted.
                      pubPath = imageStore2.pubPath image, { format: 'thumbnail' }
                      fPath = path.join testOptions.fileStoreOptions.publicDir, pubPath
                      existsFn fPath, (exists)->
                        assert ! exists, 'thumbnail format image file not deleted.'
                      
                        done()

    it 'takes an optional options object', (done)->
      imageStore = require 'image-store'
      imageStore2 = new imageStore.ImageStore testOptions

      formats =
        embedded:
          width: 400
        thumbnail:
          width:  50
          height: 80
      imageStore2.options { formats: formats }, (err, storedOps)->
        imageStore2.store testOptions.tempDummy1Path, (err, image) ->
          if err
            assert false,
              'Error returned by ImageStore.store(): ' + err.toString()

          # Pass an options object when we delete it that should cause an error
          # because image-store used its incorrect fileStoreOptions.
          options = {}
          options.fileStoreOptions = { subCollection: 'fake-dirname-sag34g54fd' }
          imageStore2.delete image, (err)->
            if err
              assert false,
                'Error returned by ImageStore.delete(): ' + err.toString()
                
            done()
