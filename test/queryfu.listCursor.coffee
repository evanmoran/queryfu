queryfu = require '../src/queryfu.coffee'

describe 'queryfu.listCursor', ->

  it 'list', ->
    cursor = queryfu.listCursor [4,3,2,1]
    cursor.hasNext().should.be.true
    cursor.next().should.equal 4
    cursor.next().should.equal 3
    cursor.next().should.equal 2
    cursor.next().should.equal 1
    cursor.hasNext().should.be.false
