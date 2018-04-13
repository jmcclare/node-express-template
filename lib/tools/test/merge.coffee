should = require('chai').should()
assert = require('chai').assert
tools = require '../index'


describe 'merge()', ->
  samples = {}

  beforeEach ->
    samples.oneItem = param1: 'contents of oneItem parameter 1'
    samples.twoItems =
      param1: 'contents of twoItems parameter 1'
      param2: 'contents of twoItems parameter 2'
    samples.threeItems =
      param1: 'contents of threeItems parameter 1'
      param2: 'contents of threeItems parameter 2'
      param3: 'contents of threeItems parameter 3'

  it 'should pass an error if updates is a string', ->
    updates = 'just some string'
    base = {}
    tools.merge base, updates, (err, mergedBase)->
      assert false, 'no error passed' if ! err
      err.toString().should.equal "TypeError: Unable to merge updates. updates must be an object."

  it 'should pass an error if updates is a Date object', (done)->
    updates = new Date()
    base = {}
    tools.merge base, updates, (err, mergedBase)->
      assert false, 'no error passed' if ! err
      err.toString().should.equal "TypeError: Unable to merge updates. updates cannot be a Date object."
      done()

  it 'should pass an error if updates is an Array', (done)->
    updates = [ 'one', 'two', 'three' ]
    base = {}
    tools.merge base, updates, (err, mergedBase)->
      assert false, 'no error passed' if ! err
      err.toString().should.equal "TypeError: Unable to merge updates. updates cannot be an Array."
      done()

  it 'should pass an error if base is a string', (done)->
    updates = {}
    base = 'just a string'
    tools.merge base, updates, (err, mergedBase)->
      assert false, 'no error passed' if ! err
      err.toString().should.equal "TypeError: Unable to merge into base. base must be an object."
      done()

  it 'should pass an error if base is an Array', (done)->
    updates = {}
    base = [ 'one', 'two', 'three' ]
    tools.merge base, updates, (err, mergedBase)->
      assert false, 'no error passed' if ! err
      err.toString().should.equal "TypeError: Unable to merge into base. base cannot be an Array."
      done()

  it 'should modify base', (done)->
    updates = tools.cloneSync samples.threeItems
    base = tools.cloneSync samples.twoItems
    tools.merge base, updates, (err, mergedBase)->
      base.param1.should.equal updates.param1
      base.param2.should.equal updates.param2
      base.param3.should.equal updates.param3
      done()

  it 'should pass instance of base', (done)->
    updates = tools.cloneSync samples.threeItems
    base = tools.cloneSync samples.twoItems
    tools.merge base, updates, (err, mergedBase)->
      base.param1.should.equal mergedBase.param1
      base.param2.should.equal mergedBase.param2
      base.param3.should.equal mergedBase.param3
      base.param1 = 'something else'
      mergedBase.param1.should.equal 'something else'
      done()

  it 'should not modify updates', (done)->
    updates = tools.cloneSync samples.threeItems
    base = tools.cloneSync samples.twoItems
    tools.merge base, updates, (err, mergedBase)->
      updates.param1.should.equal samples.threeItems.param1
      updates.param2.should.equal samples.threeItems.param2
      updates.param3.should.equal samples.threeItems.param3
      done()

  it 'should make base clone of updates if base is empty object', (done)->
    updates = samples.threeItems
    base = {}
    tools.merge base, updates, (err, mergedBase)->
      mergedBase.param1.should.equal updates.param1
      mergedBase.param2.should.equal updates.param2
      mergedBase.param3.should.equal updates.param3
      # The merged object passed to the callback should be an instance of the
      # original.
      base.param1.should.equal updates.param1
      base.param2.should.equal updates.param2
      base.param3.should.equal updates.param3
      done()

  it "should give base independent copies of updates' params", (done)->
    updates = tools.cloneSync samples.threeItems
    base = tools.cloneSync samples.twoItems
    tools.merge base, updates, (err, mergedBase)->
      base.param1.should.equal updates.param1
      base.param2.should.equal updates.param2
      base.param3.should.equal updates.param3
      updates.param2 = 'something new'
      updates.param3 = 'something else new'
      base.param2.should.equal samples.threeItems.param2
      base.param3.should.equal samples.threeItems.param3
      done()


describe 'mergeSync()', ->
  samples = {}

  beforeEach ->
    samples.oneItem = param1: 'contents of oneItem parameter 1'
    samples.twoItems =
      param1: 'contents of twoItems parameter 1'
      param2: 'contents of twoItems parameter 2'
    samples.threeItems =
      param1: 'contents of threeItems parameter 1'
      param2: 'contents of threeItems parameter 2'
      param3: 'contents of threeItems parameter 3'

  it 'should throw an error if updates is a string', ->
    updates = 'just some string'
    base = {}
    try
      tools.mergeSync base, updates
    catch e
      e.toString().should.equal "TypeError: Unable to merge updates. updates must be an object."
      caught = true
    assert caught, 'no error thrown'

  it 'should throw an error if updates is a Date object', ->
    updates = new Date()
    base = {}
    try
      tools.mergeSync base, updates
    catch e
      e.toString().should.equal "TypeError: Unable to merge updates. updates cannot be a Date object."
      caught = true
    assert caught, 'no error thrown'

  it 'should throw an error if updates is an Array', ->
    updates = [ 'one', 'two', 'three' ]
    base = {}
    try
      tools.mergeSync base, updates
    catch e
      e.toString().should.equal "TypeError: Unable to merge updates. updates cannot be an Array."
      caught = true
    assert caught, 'no error thrown'

  it 'should throw an error if base is a string', ->
    updates = {}
    base = 'just a string'
    try
      tools.mergeSync base, updates
    catch e
      e.toString().should.equal "TypeError: Unable to merge into base. base must be an object."
      caught = true
    assert caught, 'no error thrown'

  it 'should throw an error if base is an Array', ->
    updates = {}
    base = [ 'one', 'two', 'three' ]
    try
      tools.mergeSync base, updates
    catch e
      e.toString().should.equal "TypeError: Unable to merge into base. base cannot be an Array."
      caught = true
    assert caught, 'no error thrown'

  it 'should make base clone of updates if base is empty object', ->
    updates = samples.threeItems
    base = {}
    tools.mergeSync base, updates
    base.param1.should.equal updates.param1
    base.param2.should.equal updates.param2
    base.param3.should.equal updates.param3

  it "should give base independent copies of updates' params", ->
    updates = tools.cloneSync samples.threeItems
    base = tools.cloneSync samples.twoItems
    tools.mergeSync base, updates
    base.param1.should.equal updates.param1
    base.param2.should.equal updates.param2
    base.param3.should.equal updates.param3
    updates.param2 = 'something new'
    updates.param3 = 'something else new'
    base.param2.should.equal samples.threeItems.param2
    base.param3.should.equal samples.threeItems.param3

  it 'should modify base', ->
    updates = tools.cloneSync samples.threeItems
    base = tools.cloneSync samples.twoItems
    tools.mergeSync base, updates
    base.param1.should.equal updates.param1
    base.param2.should.equal updates.param2
    base.param3.should.equal updates.param3

  it 'should not modify updates', ->
    updates = tools.cloneSync samples.threeItems
    base = tools.cloneSync samples.twoItems
    tools.mergeSync base, updates
    updates.param1.should.equal samples.threeItems.param1
    updates.param2.should.equal samples.threeItems.param2
    updates.param3.should.equal samples.threeItems.param3

  it 'should return base', ->
    updates = tools.cloneSync samples.threeItems
    base = tools.cloneSync samples.twoItems
    merged = tools.mergeSync base, updates
    base.param1.should.equal merged.param1
    base.param2.should.equal merged.param2
    base.param3.should.equal merged.param3
    base.param1 = 'something else'
    merged.param1.should.equal 'something else'
