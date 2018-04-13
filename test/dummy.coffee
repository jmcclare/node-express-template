should = require('chai').should()
assert = require 'assert'


#
# Just a simple dummy example test from the Mocha homepage.
#
describe 'Array', () ->
  describe '#indexOf()', () ->
    it 'should return -1 when the value is not present', () ->
      assert.equal -1, [1,2,3].indexOf 5
      assert.equal -1, [1,2,3].indexOf 0


describe 'test variable scopes', ->
  tree = {
      "left"  : { "left" : null, "right" : null, "data" : 3 },
      "right" : null,
      "data"  : 8
  }

  samples = {}

  beforeEach ->
    samples.dummies = { dummy1: 'hi', dummy2: 'low' }
    beforeLocal = 5


  # Testing the test suite's object scope

  it 'should read the dummies', ->
    samples.dummies.dummy1.should.equal 'hi'

  it 'should read a Suite level global', ->
    tree.data.should.equal 8

  it 'should change the sample object property', ->
    samples.dummies = { nope: 'nope' }
    samples.dummies.nope.should.equal 'nope'
    assert.equal samples.dummies.dummy1, undefined

  it 'should reset the samples properties', ->
    samples.dummies.dummy1.should.equal 'hi'

  describe 'subsuite of main described Suite', ->
    it 'should read the dummies', ->
      samples.dummies.dummy1.should.equal 'hi'

    it 'should read a Suite level global', ->
      tree.data.should.equal 8

    it 'should change the sample object property', ->
      samples.dummies = { nope: 'nope' }
      samples.dummies.nope.should.equal 'nope'
      assert.equal samples.dummies.dummy1, undefined

    it 'should reset the samples properties', ->
      samples.dummies.dummy1.should.equal 'hi'
