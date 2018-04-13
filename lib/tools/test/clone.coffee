should = require('chai').should()
assert = require 'assert'
tools = require '../index'

describe 'clone', ->
  samples = {}

  beforeEach ->
    samples.array = [ 'grilled', 'fried', 'cured' ]
    samples.array['meat1'] = 'beef'
    samples.array['meat2'] = 'venison'
    samples.array['meat3'] = 'salmon'
    samples.tree =
        "left"  : { "left" : null, "right" : null, "data" : 3 }
        "right" : null
        "data"  : 8

    samples.directedAcyclicGraph =
        "left"  : { "left" : null, "right" : null, "data" : 3 }
        "data"  : 8
    samples.directedAcyclicGraph["right"] = samples.directedAcyclicGraph["left"]

    samples.types =
      "int": 42
      "str": "a string"
      "bool": true
      "null": null
      "float": 12.89
      "object": { "one": 1, "two": 2, "three": 3 }
      "nested object":
        "one": 1
        "two": 2
        "three": 3
        "four":
          "meat": "beef"
          "veggie": "celery"
          "drink": "green tea"
          "date": new Date()
          "array": [ 'grilled', 'fried', 'cured' ]
      "date": new Date()
      "array": [ 'beef', 'pork', 'chicken', 'salmon' ]
      "nested array": [
        'beef'
        'pork'
        'chicken'
        'salmon'
        [ 'grilled', 'fried', 'cured' ]
        { "one": 1, "two": 2, "three": 3 }
      ]

    samples.partiallyAssociativeArray = [ 'grilled', 'fried', 'cured' ]
    samples.partiallyAssociativeArray['restaurant'] = 'Ultimate Meat House'

  describe 'cloneSync()', ->
    it 'should clone a basic object', (done)->
      basic = { a: 'one', b: 'two' }
      basicClone = tools.cloneSync basic
      basicClone['a'].should.equal 'one'
      assert basicClone instanceof Object
      done()

    it 'should clone an array properly', (done)->
      aClone = tools.cloneSync samples.array
      aClone[0].should.equal 'grilled'
      aClone[1].should.equal 'fried'
      aClone[2].should.equal 'cured'
      aClone['meat1'].should.equal 'beef'
      aClone['meat2'].should.equal 'venison'
      aClone['meat3'].should.equal 'salmon'
      done()

    it 'should clone a tree object', (done)->
      samples.tree['data'].should.equal 8
      treeClone = tools.cloneSync samples.tree
      treeClone['data'].should.equal 8
      done()

    it 'should clone multiple nested types', (done)->
      typesClone = tools.cloneSync samples.types
      typesClone.float.should.equal samples.types.float
      typesClone['nested object'].four.array[0].should.equal samples.types['nested object'].four.array[0]
      typesClone['nested object'].four.date.toISOString.should.equal samples.types['nested object'].four.date.toISOString
      typesClone['nested array'][4][1].should.equal samples.types['nested array'][4][1]
      typesClone['nested array'][5].three.should.equal samples.types['nested array'][5].three
      done()

    it 'should make an independent copy of the original tree', (done)->
      treeClone = tools.cloneSync samples.tree
      treeClone.data.should.equal 8
      samples.tree.data = 12
      samples.tree.data.should.equal 12
      treeClone.data.should.equal 8
      treeClone.data = 15
      treeClone.data.should.equal 15
      samples.tree.data.should.equal 12
      done()

    it 'should copy data, not references', (done)->
      graphClone = tools.cloneSync samples.directedAcyclicGraph
      graphClone.left.data.should.equal 3
      graphClone.right.data.should.equal 3
      graphClone.left.data = 4
      graphClone.right.data.should.equal 3
      done()

    it 'should copy associative values in arrays', (done)->
      paaClone = tools.cloneSync samples.partiallyAssociativeArray
      paaClone[2].should.equal samples.partiallyAssociativeArray[2]
      paaClone.restaurant.should.equal samples.partiallyAssociativeArray.restaurant
      done()

  describe 'clone()', ->
    it 'should clone a basic object', (done)->
      basic = { a: 'one', b: 'two' }
      tools.clone basic, (err, copy)->
        assert false, err.toString if err
        assert copy instanceof Object
        copy['a'].should.equal 'one'
        done()

    it 'should clone an array properly', (done)->
      tools.clone samples.array, (err, aClone)->
        assert false, err.toString if err
        aClone[0].should.equal 'grilled'
        aClone[1].should.equal 'fried'
        aClone[2].should.equal 'cured'
        aClone['meat1'].should.equal 'beef'
        aClone['meat2'].should.equal 'venison'
        aClone['meat3'].should.equal 'salmon'
        done()

    it 'should clone a tree object', (done)->
      samples.tree['data'].should.equal 8
      tools.clone samples.tree, (err, treeClone)->
        assert false, err.toString if err
        treeClone['data'].should.equal 8
        done()

    it 'should clone multiple nested types', (done)->
      tools.clone samples.types, (err, typesClone)->
        assert false, err.toString if err
        typesClone.float.should.equal samples.types.float
        typesClone['nested object'].four.array[0].should.equal samples.types['nested object'].four.array[0]
        typesClone['nested object'].four.date.toISOString.should.equal samples.types['nested object'].four.date.toISOString
        typesClone['nested array'][4][1].should.equal samples.types['nested array'][4][1]
        typesClone['nested array'][5].three.should.equal samples.types['nested array'][5].three
        done()

    it 'should make an independent copy of the original tree', (done)->
      tools.clone samples.tree, (err, treeClone)->
        assert false, err.toString if err
        treeClone.data.should.equal 8
        samples.tree.data = 12
        samples.tree.data.should.equal 12
        treeClone.data.should.equal 8
        treeClone.data = 15
        treeClone.data.should.equal 15
        samples.tree.data.should.equal 12
        done()

    it 'should copy data, not references', (done)->
      tools.clone samples.directedAcyclicGraph, (err, graphClone)->
        assert false, err.toString if err
        graphClone.left.data.should.equal 3
        graphClone.right.data.should.equal 3
        graphClone.left.data = 4
        graphClone.right.data.should.equal 3
        done()

    it 'should copy associative values in arrays', (done)->
      tools.clone samples.partiallyAssociativeArray, (err, paaClone)->
        assert false, err.toString if err
        paaClone[2].should.equal samples.partiallyAssociativeArray[2]
        paaClone.restaurant.should.equal samples.partiallyAssociativeArray.restaurant
        done()
