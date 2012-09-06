
queryfu = require '../src/queryfu.coffee'

describe 'queryfu.where', ->

  it 'should equal queryfu', ->
    queryfu.should.equal queryfu.where

  it 'exists', ->
    queryfu.should.be.a 'function'

  it 'string =', ->
    implicit = queryfu('name', 'Evan').toJSON()
    explicit = queryfu('name', '=', 'Evan').toJSON()
    implicit.should.deep.equal name: 'Evan'
    explicit.should.deep.equal implicit

  it 'number =', ->
    queryfu('age', 5).toJSON().should.deep.equal age: 5
    # queryfu('age', '=', 5).toJSON().should.deep.equal age: 5

  it '!=', ->
    queryfu('name', '!=', 'Evan').toJSON().should.deep.equal name: '!=': 'Evan'

  it '<=', ->
    queryfu('age', '<=', 5).toJSON().should.deep.equal age: '<=': 5

  it '<', ->
    queryfu('age', '<', 5).toJSON().should.deep.equal age: '<': 5

  it '>', ->
    queryfu('age', '>', 5).toJSON().should.deep.equal age: '>': 5

  it '>=', ->
    queryfu('age', '>=', 5).toJSON().should.deep.equal age: '>=': 5

  it '> & <', ->
    expected = age: '>': 5, '<': 10
    queryfu('age', '>', 5).and('age', '<', 10).toJSON().should.deep.equal expected

  it '= canonicalizing', ->
    query = queryfu(d: '==': 5)
    expected = d: 5
    query.toJSON().should.deep.equal expected

  it 'age > & height <', ->
    expected = age: {'>': 5}, height: {'<': 10}
    queryfu('age', '>', 5).and('height', '<', 10).toJSON().should.deep.equal expected

  it 'object syntax =', ->
    expected = age: 5
    queryfu(age:5).toJSON().should.deep.equal expected

  it 'object syntax >', ->
    query = queryfu(age:'>':5)
    expected = age: '>': 5
    query.toJSON().should.deep.equal expected

  it 'object syntax >=, <', ->
    query = queryfu(age:'>=': 5, '<':7)
    expected = age:'>=':5,'<':7
    query.toJSON().should.deep.equal expected

  it 'object syntax &', ->
    query = queryfu(age:'>':5).and(age:'<':10)
    expected = age: '>': 5, '<': 10
    query.toJSON().should.deep.equal expected

  it '!= with & (pulls and out)', ->
    query = queryfu(d: '!=': 10).and(d: '!=': 5)
    expected = '&': [ {d: '!=': 10}, {d: '!=': 5} ]
    query.toJSON().should.deep.equal expected

  it '= merging', ->
    query = queryfu(d: '=': 5).and(d: '=': 5)
    expected = d: 5
    query.toJSON().should.deep.equal expected

  it '< merging', ->
    query = queryfu(d: '<': 5).and(d: '<': 10)
    expected = d: '<': 5
    query.toJSON().should.deep.equal expected

  it '< merging (reverse)', ->
    query = queryfu(d: '<': 10).and(d: '<': 5)
    expected = d: '<': 5
    query.toJSON().should.deep.equal expected

  it '> merging', ->
    query = queryfu(d: '>': 5).and(d: '>': 10)
    expected = d: '>': 10
    query.toJSON().should.deep.equal expected

  it '> merging (reverse)', ->
    query = queryfu(d: '>': 10).and(d: '>': 5)
    expected = d: '>': 10
    query.toJSON().should.deep.equal expected

  it '= canonicalizating with &', ->
    query = queryfu(d: '>': 10).and(d: '==': 20)
    expected = d: '>': 10, '=': 20
    query.toJSON().should.deep.equal expected

  it '= canonicalizating with & (should have error)', ->
    query = queryfu(d: '=': 10).and(d: '==': 20)
    expected = d: 20
    query.toJSON().should.deep.equal expected
    query.error().should.equal 'conflicting equality checks were found (key: d, values: 10, 20)'
