
queryfu = require '../src/queryfu.coffee'

describe 'queryfu.isCursor', ->

  it 'exists', ->
    queryfu.isCursor.should.be.a 'function'


  fn = -> false

  it 'object', ->
    queryfu.isCursor(next:fn, hasNext:fn).should.equal true
    # queryfu.isCursor(otherstuff: 1, next:fn, hasNext:fn).should.equal true

  it 'object (invalid)', ->
    queryfu.isCursor(next:fn, hasNext:'not a method').should.equal false
    queryfu.isCursor(missingNext:fn, hasNext:fn).should.equal false

  it 'buffered object', ->
    queryfu.isCursor({next:fn, hasNext:fn}, {buffered: true}).should.equal false
    queryfu.isCursor(next:fn, hasNext:fn, skip:fn, all:fn, count:fn, {buffered: true}).should.equal true
    # queryfu.isCursor(next:fn, hasNext:fn, skip:fn, missingall:fn, count:fn, {buffered: true}).should.equal false

  it 'other', ->
    queryfu.isCursor(5).should.equal false
    queryfu.isCursor(null).should.equal false
    queryfu.isCursor(undefined).should.equal false
    queryfu.isCursor('notanobject').should.equal false
