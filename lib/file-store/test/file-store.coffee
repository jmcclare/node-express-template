path = require 'path'
fs = require 'fs.extra'
util = require 'util'

require('chai').should()
# Use chai's assert, not node.js' included assert
assert = require('chai').assert

uuid = require 'uuid'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'


existsFn = fs.exists || path.exists
existsSync = fs.existsSync || path.existsSync


describe 'module', () ->
  it 'should create a global instance of itself', () ->
    fileStore = require 'file-store'
    fileStore.setOption 'foo2', 5
    fileStore2 = require 'file-store'
    fileStore2.getOption('foo2').should.equal 5

  it 'should provide a FileMissingError class', () ->
    FileMissingError = require('file-store').Error.FileMissingError
    fmerror = new FileMissingError()
    fmerror.name.should.equal 'FileMissingError'
    assert.ok fmerror.message, 'No message property for FileMissingError class.'
    assert fmerror.toString() == 'FileMissingError: File does not exist.'
    fmerror = new FileMissingError('Some message about this error.')
    assert fmerror.toString() == 'FileMissingError: Some message about this error.'


describe 'FileStore', () ->
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
    testOptions.publicDir = '/tmp/' + uuid.v4()
    testOptions.fileDataDir = '_dynamic'
    testOptions.collection = 'blob'
    testOptions.subCollection = ''

    # Create the publicDir
    oldMask = process.umask 0o000
    mkdirp testOptions.publicDir, 0o775, (err) ->
      assert(false, err) if err
      process.umask oldMask

      # Set some options just for the tests. These should have no effect on the
      # FileStore object.
      testOptions.sampleDataDir = '/tmp/' + uuid.v4()
      # Create the sampleDataDir
      oldMask = process.umask 0o000
      mkdirp testOptions.sampleDataDir, 0o775, (err) ->
        assert(false, err) if err
        process.umask oldMask
        dummy1Path = path.join(__dirname, 'sample-files/dummy1.txt')
        tempDummy1Path = path.join(testOptions.sampleDataDir, 'dummy1.txt')
        testOptions.tempDummy1Path = tempDummy1Path
        dummy2Path = path.join(__dirname, 'sample-files/dummy2.txt')
        tempDummy2Path = path.join(testOptions.sampleDataDir, 'dummy2.txt')
        testOptions.tempDummy2Path = tempDummy2Path
        fs.copy dummy1Path, tempDummy1Path, (err) ->
          assert false, err.toString() if err
          fs.copy dummy2Path, tempDummy2Path, (err) ->
            assert false, err.toString() if err
            done()

  afterEach (done) ->
    # Delete the publicDir and sampleDataDir
    rimraf testOptions.publicDir, (err1) ->
      rimraf testOptions.sampleDataDir, (err2) ->
        assert(false, err1) if err1
        assert(false, err2) if err2
        done()

  describe 'options()', ->
    it 'should return the full options object', () ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore()
      fileStore2.setOption 'dummy', 'some string'
      fileStore2.options (err, options)->
        assert(false, err) if err
        options['dummy'].should.equal 'some string'

    it 'should merge supplied options into its own', () ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore()
      fileStore2.setOption 'dummy', 'some string'
      fileStore2.options { anOption: 'an option string' }, (err, options)->
        assert false, err if err
        fileStore2.optionsSync().anOption.should.equal 'an option string'
        fileStore2.optionsSync()['dummy'].should.equal 'some string'

    it 'should reset options to defaults', ()->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore()

      fileStore2.setOption 'fileDataDir', 'uploads'
      fileStore2.setOption 'dummy8', 'some other string'
      fileStore2.optionsSync { anotherOption: 'another option string' }

      fileStore2.resetOptions (err, options)->
        assert false, err if err

        assert typeof fileStore2.optionsSync()['fileDataDir'] == 'string'
        assert.notOk fileStore2.optionsSync()['dummy8']
        assert.notOk fileStore2.optionsSync()['anotherOption']

    it 'should reset options and merge the supplied object', ()->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore()

      fileStore2.setOption 'fileDataDir', 'uploads'
      fileStore2.setOption 'dummy8', 'some other string'

      newOptions =
        option1: 'some value'
        option2: 'some other value'
        collection: 'some-random-collection-name-lsat23oifbw398iv'

      fileStore2.resetOptions newOptions, (err, options)->

        assert typeof fileStore2.optionsSync()['fileDataDir'] == 'string'
        fileStore2.optionsSync()['collection'].should.equal 'some-random-collection-name-lsat23oifbw398iv'
        assert.notOk fileStore2.optionsSync()['dummy8']
        assert.notOk fileStore2.optionsSync()['anotherOption']

  describe 'optionsSync()', ->
    it 'should set and return options', () ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore()
      fileStore2.setOption 'foo', 5
      fileStore2.getOption('foo').should.equal 5

    it 'should return the full options object', () ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore()
      fileStore2.setOption 'dummy', 'some string'
      fileStore2.optionsSync()['dummy'].should.equal 'some string'

    it 'should merge supplied options into its own', () ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore()
      fileStore2.setOption 'dummy', 'some string'
      fileStore2.optionsSync { anOption: 'an option string' }
      fileStore2.optionsSync().anOption.should.equal 'an option string'
      fileStore2.optionsSync()['dummy'].should.equal 'some string'

    it 'should reset options to defaults', ()->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore()

      fileStore2.setOption 'fileDataDir', 'uploads'
      fileStore2.setOption 'dummy8', 'some other string'
      fileStore2.optionsSync { anotherOption: 'another option string' }

      fileStore2.resetOptionsSync()

      assert typeof fileStore2.optionsSync()['fileDataDir'] == 'string'
      assert.notOk fileStore2.optionsSync()['dummy8']
      assert.notOk fileStore2.optionsSync()['anotherOption']

    it 'should reset options and merge the supplied object', ()->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore()

      fileStore2.setOption 'fileDataDir', 'uploads'
      fileStore2.setOption 'dummy8', 'some other string'

      newOptions =
        option1: 'some value'
        option2: 'some other value'
        collection: 'some-random-collection-name-lsat23oifbw398iv'

      fileStore2.resetOptionsSync(newOptions)

      assert typeof fileStore2.optionsSync()['fileDataDir'] == 'string'
      fileStore2.optionsSync()['collection'].should.equal 'some-random-collection-name-lsat23oifbw398iv'
      assert.notOk fileStore2.optionsSync()['dummy8']
      assert.notOk fileStore2.optionsSync()['anotherOption']

  describe 'constructor', ->
    it 'should create a new instance of FileStore', () ->
      fileStore = require 'file-store'
      fileStore.setOption 'foo3', 5
      fileStore2 = new fileStore.FileStore()
      assert.isUndefined fileStore2.getOption('foo3'), 'unset option foo3 should be undefined'
      fileStore2.setOption 'foo3', 6
      fileStore.getOption('foo3').should.equal 5, 'option not at proper set value'
      fileStore2.getOption('foo3').should.equal 6, 'option not at proper set value'

    it 'should set options supplied to constructor', ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore { anOption: 'an option string' }
      fileStore2.optionsSync().anOption.should.equal 'an option string'

    it 'should set default options', ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore()
      #assert.ok fileStore2.options().publicDir, 'default publicDir not set'
      assert typeof fileStore2.optionsSync().publicDir == 'string',
        'default publicDir not set'
      assert typeof fileStore2.optionsSync().fileDataDir == 'string',
        'default fileDataDir not set'
      assert typeof fileStore2.optionsSync().collection == 'string',
        'default collection not set'

  describe 'store()', ->
    it 'should create the file data and collection dirs', (done) ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions
      # Tell FileStore to store this sample file.
      fileStore2.store testOptions.tempDummy1Path, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        collectionDir = path.join(testOptions.publicDir, testOptions.fileDataDir, testOptions.collection)
        existsFn collectionDir, (exists) ->
          if !exists
            assert false, 'collectionDir was not created for stored file.'
          done()

    it 'should return an error if source file does not exist', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions
      fileStore2.store '/non/existant.txt', (err, file) ->
        if ! err
          assert false, 'No Error returned for non-existant source file.'
        err.name.should.equal 'FileMissingError', 'Wrong class of error returned.'
        done()

    it 'should convert file names to something url safe', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      # Create a sample file with an invalid name
      dummy1Path = path.join(__dirname, 'sample-files/dummy1.txt')
      tempBadNamePath = path.join(testOptions.sampleDataDir, 'Name WITH spaces.txt')
      fs.copy dummy1Path, tempBadNamePath, (err) ->
        assert false, err.toString() if err

        # Tell FileStore to store a sample file.
        fileStore2.store tempBadNamePath, (err, file) ->
          if err
            assert false,
              'Error returned by FileStore.store(): ' + err.toString()
          assert file.fileName == 'name-with-spaces.txt', "filename wasn't made URL sanitised."
          done()

    it 'should make unique paths for files with same name', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      # Create a sample file
      dummy1Path = path.join(__dirname, 'sample-files/dummy1.txt')
      sameNamePath = path.join(testOptions.sampleDataDir, 'same-name.txt')
      fs.copy dummy1Path, sameNamePath, (err) ->
        assert false, err.toString() if err

        # Make sure it doesn't delete the original file. We are going to store
        # it twice.
        options = deleteOriginal: false

        # Tell FileStore to store the sample file.
        fileStore2.store sameNamePath, options, (err, file1) ->
          if err
            assert false,
              'Error returned by FileStore.store(): ' + err.toString()

          # Tell FileStore to store the same file again.
          fileStore2.store sameNamePath, options, (err, file2) ->
            if err
              assert false,
                'Error returned by FileStore.store(): ' + err.toString()

            # The public paths for these files should be different.
            pubPath1 = fileStore2.pubPath file1
            pubPath2 = fileStore2.pubPath file2
            assert pubPath1 != pubPath2, 'Both files were given the same public path.'

            done()

    it 'should remove source file by default', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      # Tell FileStore to store this sample file.
      fileStore2.store testOptions.tempDummy1Path, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()

        # Make sure the source file is gone
        existsFn testOptions.tempDummy1Path, (exists) ->
          if exists
            assert false, 'Source file was not removed.'
          done()

    it 'should not remove source file when configured not to', (done)->
      fileStore = require 'file-store'
      testOptions.deleteOriginal = false
      fileStore2 = new fileStore.FileStore testOptions

      # Tell FileStore to store this sample file.
      fileStore2.store testOptions.tempDummy1Path, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()

        # Make sure the source file is gone
        existsFn testOptions.tempDummy1Path, (exists) ->
          if ! exists
            assert false, 'Source file was removed.'
          done()

    it 'should not remove source file when told not to', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      # Tell FileStore to store this sample file.
      options =
        deleteOriginal: false
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()

        # Make sure the source file is gone
        existsFn testOptions.tempDummy1Path, (exists) ->
          if ! exists
            assert false, 'Source file was removed.'
          done()

    it 'should take an optional options object parameter', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      # Tell FileStore to store this sample file with a blank options object.
      options = {}
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()

        done()

    it 'should pass an error when options is not an object', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      # Tell FileStore to store this sample file with a string for options.
      fileStore2.store testOptions.tempDummy1Path, 'a string', (err, file) ->
        if ! err
          assert false,
            'No error returned by FileStore.store() for invalid options type'
        err.toString().should.equal "TypeError: options must be an object."
        done()

    it 'should pass an error when options is a Date', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      # Tell FileStore to store this sample file with a Date object for
      # options.
      options = new Date()
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if ! err
          assert false,
            'No error returned by FileStore.store() for invalid options type'
        err.toString().should.equal "TypeError: options cannot be a Date object."
        done()

    it 'should pass an error when options is an Array', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      # Tell FileStore to store this sample file with a Array for options.
      options = ['one', 'two', 'three']
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if ! err
          assert false,
            'No error returned by FileStore.store() for invalid options type'
        err.toString().should.equal "TypeError: options cannot be an Array."
        done()

    it 'takes a fileName parameter in the options object', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { fileName: 'Some name I made up' }

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()

        # Test for a slash and the cleaned-up version of our fileName
        re = /\/some-name-i-made-up$/
        fPath = fileStore2.pubPath file
        assert re.test(fPath), 'file name in ID does not match supplied name.'
        
        # Make sure file.fileName matches the safe version of our fileName option
        file.fileName.should.equal 'some-name-i-made-up'
        done()

    it 'should pass an error if options.fileName is not a string', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { fileName: ['an', 'array', 'of', 'strings'] }
      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if ! err
          assert false,
            'No error returned for invalid fileName'
        err.toString().should.equal "TypeError: options.fileName must be a string."
        done()

    it 'defaults fileName to originalFileName, if provided', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = {
        fileName: ''
        originalFileName: 'some-file-name-f45gs4g.txt'
      }

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()

        # Test for a slash and the cleaned-up version of our fileName
        re = /\/some-file-name-f45gs4g.txt$/
        fPath = fileStore2.pubPath file
        assert re.test(fPath), 'file name in ID does not match supplied name.'
        
        # Make sure file.fileName matches the safe version of our fileName option
        file.fileName.should.equal 'some-file-name-f45gs4g.txt'
        done()

    it 'defaults fileName to file name in path if no originalFileName', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = {
        fileName: ''
        originalFileName: ''
      }
      suppliedFileName = path.basename testOptions.tempDummy1Path

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()

        # Test for a slash and the cleaned-up version of our fileName
        re = /\/some-file-name-f45gs4g.txt$/
        fPath = fileStore2.pubPath file
        path.basename(fPath).should.equal suppliedFileName
        
        # Make sure file.fileName matches the safe version of our fileName option
        file.fileName.should.equal suppliedFileName
        done()

    it 'takes a originalFileName parameter in the options object', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { originalFileName: 'Some other name I made up' }

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()

        # Test for a slash and the cleaned-up version of our fileName
        re = /\/some-other-name-i-made-up$/
        fPath = fileStore2.pubPath file
        assert re.test(fPath), 'file name in ID does not match supplied name.'
        
        # Make sure file.fileName matches the safe version of our fileName option
        file.fileName.should.equal 'some-other-name-i-made-up'
        done()

    it 'should pass an error if options.originalFileName is not a string', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { originalFileName: ['an', 'array', 'of', 'strings'] }
      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if ! err
          assert false,
            'No error returned for invalid originalFileName'
        err.toString().should.equal "TypeError: options.originalFileName must be a string."
        done()

    it 'defaults originalFileName to fileName if available', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = {
        fileName: 'some-file-name-f45gs4g.txt'
        originalFileName: ''
      }

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        
        # Make sure file.originalFileName matches the value of fileName we
        # passed in
        file.originalFileName.should.equal 'some-file-name-f45gs4g.txt'
        done()

    it 'defaults originalFileName to name in path if no fileName available', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = {
        fileName: ''
        originalFileName: ''
      }
      pathName = path.basename testOptions.tempDummy1Path

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        
        # Make sure file.originalFileName matches the value of fileName we
        # passed in
        file.originalFileName.should.equal pathName
        done()

    it 'uses fileName over originalFileName', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options =
        fileName: 'Some name I made up'
        originalFileName: 'Some other name I made up'

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()

        # Test for a slash and the cleaned-up version of our fileName
        re = /\/some-name-i-made-up$/
        fPath = fileStore2.pubPath file
        assert re.test(fPath), 'file name in ID does not match supplied name.'
        
        # Make sure file.fileName matches the safe version of our fileName option
        file.fileName.should.equal 'some-name-i-made-up'
        done()

    it 'takes a name parameter in the options object', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { name: 'Some other name I made up' }

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        
        # Make sure file.fileName matches the safe version of our fileName option
        file.name.should.equal options.name
        done()

    it 'should pass an error if options.name is not a string', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { name: ['an', 'array', 'of', 'strings'] }
      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if ! err
          assert false,
            'No error returned for invalid originalFileName'
        err.toString().should.equal "TypeError: options.name must be a string."
        done()

    it 'defaults name to cleaned fileName', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = {
        fileName: 'some file name ftg4345gs4g.txt'
      }

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        
        # Make sure file.originalFileName matches the value of fileName we
        # passed in
        file.name.should.equal file.fileName
        done()

    it 'takes a description parameter in the options object', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { description: 'Some description I made up' }

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        
        # Make sure file.fileName matches the safe version of our fileName option
        file.description.should.equal options.description
        done()

    it 'passes an error if options.description is not a string', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { description: ['an', 'array', 'of', 'strings'] }
      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if ! err
          assert false,
            'No error returned for invalid description'
        err.toString().should.equal "TypeError: options.description must be a string."
        done()

    it 'defaults a description to blank', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = {}

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        
        # Make sure file.fileName matches the safe version of our fileName option
        file.description.should.equal ''
        done()

    it 'should take a collection parameter in the options object', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { collection: 'user-upload' }

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, id) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        # Make sure our collection dir was created
        collectionDir = path.join(
          testOptions.publicDir,
          testOptions.fileDataDir,
          options.collection,
          fileStore2.optionsSync().subCollection
        )
        existsFn collectionDir, (exists) ->
          if !exists
            assert false, 'collectionDir was not created for stored file.'
          done()

    it 'should pass an error if options.collection is not a string', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { collection: ['an', 'array', 'of', 'strings'] }
      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if ! err
          assert false,
            'No error returned for invalid collection'
        err.toString().should.equal "TypeError: options.collection must be a string."
        done()

    it 'should operate with a blank collection name', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { collection: '' }

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        # Make sure our collection dir was created
        collectionDir = path.join(
          testOptions.publicDir,
          testOptions.fileDataDir,
          '',
          testOptions.subCollection
        )
        existsFn collectionDir, (exists) ->
          if !exists
            assert false, 'collectionDir was not created for stored file.'
          done()

    it 'should take a subCollection parameter in the options object', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { subCollection: 'pet-photo' }

      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        # Make sure our collection dir was created
        collectionDir = path.join(
          testOptions.publicDir,
          testOptions.fileDataDir,
          testOptions.collection,
          'pet-photo'
        )
        existsFn collectionDir, (exists) ->
          if !exists
            assert false, 'subCollectionDir was not created for stored file.'
          done()

    it 'should pass an error if options.subCollection is not a string', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { subCollection: ['an', 'array', 'of', 'strings'] }
      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if ! err
          assert false,
            'No error returned for invalid subCollection'
        err.toString().should.equal "TypeError: options.subCollection must be a string."
        done()

    it 'should pass an error if collection is blank and subCollection is not', (done)->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { collection: '', subCollection: 'a-string' }
      # Tell FileStore to store this sample file with our options object.
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if ! err
          assert false,
            'No error returned for invalid subCollection'
        err.toString().should.equal "Error: Cannot have a subCollection without a collection."

        # Cover the case where the current collection is blank and we try to
        # use a subCollection.
        fileStore2.setOption 'collection', ''
        options = { subCollection: 'a-string' }
        fileStore2.store testOptions.tempDummy2Path, options, (err, file) ->
          if ! err
            assert false,
              'No error returned for invalid subCollection'
          err.toString().should.equal "Error: Cannot have a subCollection without a collection."
          done()

  describe 'pubPath()', ->
    it 'should give a public path based on a file object', (done) ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions
      # Tell FileStore to store a sample file.
      fileStore2.store testOptions.tempDummy1Path, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        assert typeof file == 'object', "didn't return file object"
        pubPath = fileStore2.pubPath file
        assert.ok pubPath
        assert typeof pubPath == 'string'
        fullPath = path.join testOptions.publicDir, pubPath
        existsFn fullPath, (exists) ->
          if !exists
            assert false, 'pubPath did not point to stored file.'
          done()

    it 'should take an optional options object parameter', (done) ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      fileStore2.store testOptions.tempDummy1Path, (err, file) ->
        if err
          assert false, err.toString()

        options = { fileDataDir: '/tmp/some-other-dir-sgejnd43f43f' }
        pPath = fileStore2.pubPath file, options
        re = /\/tmp\/some-other-dir-sgejnd43f43f/
        assert re.test(pPath), 'returned pubPath does not contain fileDataDir.'
        done()

    it 'should throw an error when options is not an object', (done) ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      options = { subCollection: 'a-string' }
      fileStore2.pubPath
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false, err.toString()

        options = 'ajstring'
        try
          fileStore2.pubPath file, options
        catch err
          caught = true
        assert caught, 'No error thrown for invalid options object.'

        done()

    it "uses file's stored options over store's options", (done)->
      # For anything specifying the file's location within the store, files
      # should use options in the following order or priority:
      #  * options passed to pubPath
      #  * their own stored options (which should always exist)
      #  * the store's options (only if the file somehow doesn't have its own)
 
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions

      # Set an option that affects the pubPath of stored files.
      fileStore2.optionsSync { collection: 'stuff' }

      fileStore2.store testOptions.tempDummy1Path, (err, file) ->
        if err
          assert false, err.toString()

        # Make the fileStore object's collection option differ from the one the
        # file was stored with.
        fileStore2.optionsSync { collection: 'animals' }

        pPath = fileStore2.pubPath file
        re = /stuff/
        assert re.test(pPath), "returned pubPath does not contain file's stored collection name"

        done()

  describe 'delete()', ->
    it 'should take a file object and delete the associated file', (done) ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions
      # Tell FileStore to store a sample file.
      fileStore2.store testOptions.tempDummy1Path, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        fileStore2.delete file, (err) ->
          if err
            assert false,
              'Error returned by FileStore.delete(): ' + err.toString()

          # Make sure the file was deleted
          filePath = path.join fileStore2.getOption('publicDir'), fileStore2.pubPath file
          existsFn filePath, (exists) ->
            if exists
              assert false, 'File was not deleted.'
          done()

    it 'should not delete any other files', (done) ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions
      # Tell FileStore to store a sample file.
      fileStore2.store testOptions.tempDummy1Path, (err, file1) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        # Tell FileStore to store another sample file.
        fileStore2.store testOptions.tempDummy2Path, (err, file2) ->
          if err
            assert false,
              'Error returned by FileStore.store(): ' + err.toString()

          fileStore2.delete file1, (err) ->
            if err
              assert false,
                'Error returned by FileStore.delete(): ' + err.toString()

            # Make sure file2 was not deleted
            filePath = path.join fileStore2.getOption('publicDir'), fileStore2.pubPath file2
            existsFn filePath, (exists) ->
              if !exists
                assert false, 'File was deleted.'
            done()

    it 'should pass an error if no file exists for the given file object', (done) ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions
      fileStore2.store testOptions.tempDummy1Path, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        fakeFile =
          id: '8754iu4h93hdgjk56shhifnh3wh399nfc854hf94hng'
          fileName: 'some-other-random-name-st34f.txt'
          collection: 'wut'
          subCollection: 'made-this-up-too'
        fileStore2.delete fakeFile, (err) ->
          if ! err
            assert false,
              'No error returned for invalid file object'
          err.name.should.equal 'FileMissingError', 'Wrong class of error returned.'
          done()

    it 'should take an optional options object parameter', (done) ->
      fileStore = require 'file-store'
      fileStore2 = new fileStore.FileStore testOptions
      options = { subCollection: 'optionsTestUploads' }
      fileStore2.store testOptions.tempDummy1Path, options, (err, file) ->
        if err
          assert false,
            'Error returned by FileStore.store(): ' + err.toString()
        fileStore2.delete file, options, (err) ->
          if err
            assert false,
              'Error returned by delete() when given valid options.'

          # Make sure the file was deleted
          filePath = path.join fileStore2.getOption('publicDir'), fileStore2.pubPath file, options
          existsFn filePath, (exists) ->
            if exists
              assert false, 'File was not deleted.'

          done()
