
queryfu = require '../src/queryfu.coffee'

describe 'queryfu.toMongo', ->

  it 'string =', ->
    implicit = queryfu('name', 'Evan').toMongo()
    explicit = queryfu('name', '=', 'Evan').toMongo()
    implicit.should.deep.equal name: 'Evan'
    explicit.should.deep.equal implicit

  it 'number =', ->
    queryfu('age', 5).toMongo().should.deep.equal age: 5

  it '<=', ->
    queryfu('age', '<=', 5).toMongo().should.deep.equal age: '$lte': 5

  it '!=', ->
    queryfu('name', '!=', 'Evan').toMongo().should.deep.equal name: '$not': 'Evan'

  it '<', ->
    queryfu('age', '<', 5).toMongo().should.deep.equal age: '$lt': 5

  it '>', ->
    queryfu('age', '>', 5).toMongo().should.deep.equal age: '$gt': 5

  it '>=', ->
    queryfu('age', '>=', 5).toMongo().should.deep.equal age: '$gte': 5

  it '> & <', ->
    query = queryfu('age', '>', 5).and('age', '<', 10)
    expected = age: '$gt': 5, '$lt': 10
    query.toMongo().should.deep.equal expected

  it '= canonicalizing', ->
    query = queryfu(d: '==': 5)
    expected = d: 5
    query.toMongo().should.deep.equal expected

  it 'age > & height <', ->
    query = queryfu('age', '>', 5).and('height', '<', 10)
    expected = age: {'$gt': 5}, height: {'$lt': 10}
    query.toMongo().should.deep.equal expected

  it 'object syntax =', ->
    expected = age: 5
    queryfu(age:5).toMongo().should.deep.equal expected

  it 'object syntax >', ->
    query = queryfu(age:'>':5)
    expected = age: '$gt': 5
    query.toMongo().should.deep.equal expected

  it 'object syntax >=, <', ->
    query = queryfu(age:'>=': 5, '<':7)
    expected = age:'$gte':5,'$lt':7
    query.toMongo().should.deep.equal expected

  it 'object syntax &', ->
    query = queryfu(age:'>':5).and(age:'<':10)
    expected = age: '$gt': 5, '$lt': 10
    query.toMongo().should.deep.equal expected

  it '!= with & (pulls and out)', ->
    query = queryfu(d: '!=': 10).and(d: '!=': 5)
    expected = '$and': [ {d: '$not': 10}, {d: '$not': 5} ]
    query.toMongo().should.deep.equal expected

  it '= merging', ->
    query = queryfu(d: '=': 5).and(d: '=': 5)
    expected = d: 5
    query.toMongo().should.deep.equal expected

  it '< merging', ->
    query = queryfu(d: '<': 5).and(d: '<': 10)
    expected = d: '$lt': 5
    query.toMongo().should.deep.equal expected

  it '< merging (reverse)', ->
    query = queryfu(d: '<': 10).and(d: '<': 5)
    expected = d: '$lt': 5
    query.toMongo().should.deep.equal expected

  it '> merging', ->
    query = queryfu(d: '>': 5).and(d: '>': 10)
    expected = d: '$gt': 10
    query.toMongo().should.deep.equal expected

  it '> merging (reverse)', ->
    query = queryfu(d: '>': 10).and(d: '>': 5)
    expected = d: '$gt': 10
    query.toMongo().should.deep.equal expected

  it '= canonicalizating with &', ->
    query = queryfu(d: '>': 10).and(d: '==': 20)
    expected = '$and': [{d: '$gt': 10}, {d: 20}]
    query.toMongo().should.deep.equal expected

  it '= canonicalizating with & (should have error)', ->
    query = queryfu(d: '=': 10).and(d: '==': 20)
    expected = d: 20
    query.toMongo().should.deep.equal expected
    query.error().should.equal 'conflicting equality checks were found (key: d, values: 10, 20)'
