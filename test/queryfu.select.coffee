
queryfu = require '../src/queryfu.coffee'

evan = {name: 'Evan', height: 3, male: true, games: ['Guild Wars 2', 'Starcraft 2', 'Starcraft', 'Quake', 'Myst']}
james = {name: 'James', height: 3.12, male: true, games: ['Starcraft 2', 'Starcraft', 'Alpha Centauri', 'Skyrim']}
laura = {name: 'Laura', height: 2.8, male: false, games: ['Skyrim', 'Obvlion']}
nick =  {name: 'Nick', height: 3.1, male: true, games: ['Guild Wars 2', 'Starcraft 2', 'Starcraft', 'Quake']}
sarah = {name: 'Sarah', height: 1.5, male: false, games: []}
batman = {name: 'Batman', height: 5, male: true, games: ['Metropolis','Gotham']}

models = [
  evan
  laura
  james
  nick
  sarah
  batman
]
#   evan, laura, james, nick, sarah, batman

modelsEmpty = []

describe 'queryfu.select', ->
  it 'all', ->
    queryfu().select(models).toArray().should.deep.equal models

  it '=', ->
    query = queryfu(name:'James')
    query.select(models).toArray().should.deep.equal [james]

  it '<', ->
    query = queryfu(height: '<':3)
    query.select(models).toArray().should.deep.equal [laura, sarah]

  it '<=', ->
    query = queryfu(height: '<=':3)
    query.select(models).toArray().should.deep.equal [evan, laura, sarah]

  it '>=', ->
    query = queryfu(height: '>=':3)
    query.select(models).toArray().should.deep.equal [evan, james, nick, batman]

  it '>', ->
    query = queryfu(height: '>':3)
    query.select(models).toArray().should.deep.equal [james, nick, batman]

  it '!=', ->
    query = queryfu(name: '!=':'James')
    query.select(models).toArray().should.deep.equal [evan, laura, nick, sarah, batman]

  it '= false', ->
    query = queryfu(male:false)
    query.select(models).toArray().should.deep.equal [laura, sarah]

  it '= true', ->
    query = queryfu(male:true)
    query.select(models).toArray().should.deep.equal [evan, james, nick, batman]

  it '<= & true', ->
    query = queryfu(male:true, height: '<=':3)
    query.select(models).toArray().should.deep.equal [evan]

  it '<= & true (case 2)', ->
    query = new queryfu.QueryFu('&': [{male:true}, {height: '<=':3}])
    query.select(models).toArray().should.deep.equal [evan]
