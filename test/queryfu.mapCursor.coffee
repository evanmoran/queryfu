queryfu = require '../src/queryfu.coffee'

describe 'queryfu.mapCursor', ->

  it 'map (null)', ->
    expect(queryfu.mapCursor null).to.be.null

  it 'map', ->
    cursor = queryfu.listCursor [4,3,2,1]
    cursor2 = queryfu.mapCursor cursor, (v) -> v + 1
    cursor2.all().should.deep.equal [5,4,3,2]

  it 'map remove on undefined', ->
    cursor = queryfu.listCursor [4,3,2,1]
    cursor2 = queryfu.mapCursor cursor, (v) -> if v % 2 then v else undefined
    cursor2.all().should.deep.equal [3,1]

  it 'map returns null', ->
    cursor = queryfu.listCursor [4,3,2,null]
    cursor2 = queryfu.mapCursor cursor, (v) -> v
    cursor2.all().should.deep.equal [4,3,2,null]


