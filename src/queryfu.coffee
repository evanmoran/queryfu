
# queryfu
# ====================================================================
# An intermediate query language for ninjas. Write your query once. Use it in any system.
#
# ### Usage
#
# There are four pretty similar ways to use queryfu:
#
# queryfu(path, value)
#
# queryfu(path, operator, value)
#
# queryfu(pathValue)
#
# queryfu(pathOperatorValue)
#
#     path                String of attribute with optional dot syntax (e.g. 'name', 'person.name')
#     value               String, Number, Boolean, Date, or null that defines value being compared
#     operator            (Optional) String representing operator:  <, <=, =, >=, >, !=
#     pathValue           Object that maps path to value, meaning query for quality
#     pathOperatorValue   Object that maps path to operator to value: age:'<':5
#
#  Basics
#
#     queryfu(age, 4).toJSON()                            # => {age:4}
#     queryfu(age:4).toJSON()                             # => {age:4}
#     queryfu('age', '<=', 4).toJSON()                    # => {age:{'<=':4}}
#     queryfu(age:'<=':4).toJSON()                        # => {age:{'<=':4}}
#     queryfu(age:'<=':4).and(height:'>=':10).toJSON()    # => {age:{'<=':4}, height:{'>':10}}
#
#  Match
#
#     queryfu(age:'<=':4).match(name:'Evan', age:4)       # => true
#     queryfu(age:'<':4).match(name:'Evan', age:4)        # => false
#
#  Mongo
#
#     queryfu(age:'<':4).toMongo()                        # => {age:{'$lt':4}}
#     queryfu(age:'<':4).and(height:'>=':10).toMongo()    # => {age:{'$lt':4, '$gte':10}}
#

queryfu = (path, operator, value) ->

  qf = new QueryFu
  qf.where.apply(qf, arguments)

root = @

_isArrayEqual = (arr1, arr2) ->
  if arr1.length != arr2.length
    return false
  for v,k in arr1
    if arr2[k] != v
      return false
  true

_hasOnlyKey = (obj, key) ->
  (_.isObject obj) and _isArrayEqual (_.keys obj), [key]

_mergeFailed = {}
_mergeOp = (operator, currentValue, value, key, errorList) ->
  switch operator
    when '<', '<='
      return Math.min(value, currentValue)
    when '>=', '>'
      return Math.max(value, currentValue)
    when '='
      if currentValue != value
        errorList.push "conflicting equality checks were found (key: #{key}, values: #{currentValue}, #{value})"
      return value
  _mergeFailed

class QueryFu

  constructor: (json = {}, errors = [])->
    @_query = _.clone json
    @_errors = errors.slice 0
    @_match = null

  _inplaceWhere: (path, operator, value) ->
    @_match = null
    # Handle multiple object parameters
    if arguments.length == 1 and _.isObject path
      for k, v of path
        @_inplaceWhere k, v
      return @

    if arguments.length == 2
      # Handle multiple operator parameters
      if _.isObject operator
        for k, v of operator
          @_inplaceWhere path, k, v
        return @

      # Operator defaults to =
      value = operator
      operator = '='

    # Canonicalise equals
    operator = '=' if operator == '=='

    # Use explicit conjunction if there is a key collision
    if (expr = @_query[path])?
      # Explicitise equals
      expr = (@_query[path] = {'=': expr}) if not _.isObject expr

      if not expr[operator]?
        # No operator collision. Implicit conjunction
        expr[operator] = value
      else
        #operator collision
        merged = _mergeOp operator, @_query[path][operator], value, path, @_errors
        if merged != _mergeFailed
          @_query[path][operator] = merged
          if _hasOnlyKey @_query[path], '='
            @_query[path] = @_query[path]['=']
        else
          # Merge failed. Explicit conjunction
          subquery = {}
          subquery[path] = {}
          subquery[path][operator] = value
          @_query = '&': [ @_query, subquery ]
    else
      switch operator
        when '=', '=='
          @_query[path] = value
        when '!=', '<', '<=', '>=', '>'
          expression = {}
          expression[operator] = value
          @_query[path] = expression

    # Return self
    @

  # Where that doesn't change itself
  where: ->
    q = new QueryFu @_query, @_errors
    q._inplaceWhere arguments...

  # `and` is an alias for where
  and: ->
    @where arguments...

  error: ->
    @_errors.join('\n')

  # toJSON
  toJSON: ->
    @_query

  _toMongoOp = (op, value) ->
    answer = {}
    opMap =
      '<': '$lt'
      '>': '$gt'
      '<=': '$lte'
      '>=': '$gte'
    if opMap[op]?
      answer[opMap[op]] = value
    else if op == '!='
      answer['$not'] = value
    answer

  _exprToMongo = (expr) ->
    if _.isObject expr
      mongoExpr = {}
      for op, val of expr
        _.extend mongoExpr, (_toMongoOp op, val)
      mongoExpr
    else
      expr

  # toMongo
  toMongo: (query = @_query) ->
    if _hasOnlyKey query, '&'
      return '$and': (_.map query['&'], @toMongo)
    mongo = {}
    equalities = {}
    for path, expr of query
      mongo[path] = _exprToMongo expr
      if expr['=']?
        equalities[path] = expr['=']
    if (_.keys equalities).length
      mongo = '$and': [mongo, @toMongo equalities]
    mongo

  # queryfu.select
  # ----------------------------------------------------------------------------------------
  #
  # queryfu(...).select(cursorOrArray)
  #
  #     cursorOrArray     Array or Object that is a cursor and contains `next` and `hasNext`
  #
  # Examples:
  #
  #     queryfu(n: '<':2).select([{s:'a', n:1},{s:'b', n:2}]).toArray()     # => [{s:'a', n:1}]
  #     queryfu(n: '<=':2).select([{s:'a', n:1},{s:'b', n:2}]).toArray()    # => [{s:'a', n:1,{s:'b', n:2}}]
  #

  select: (cursorOrArray) ->
    throw 'queryfu.select: Cursor or array expected for argument one' unless (_.isArray cursorOrArray) or (queryfu.isCursor cursorOrArray)
    cursor = if _.isArray cursorOrArray then queryfu.listCursor (cursorOrArray) else cursorOrArray
    new CursorFu (new FilteredFu cursor, (_.bind @match, @))

  # _matcherOp: generate matcher function for operator
  _matcherOp = (op, val, path = '') ->
    switch op
      when '='  then (obj) -> obj == val
      when '<'  then (obj) -> obj < val
      when '<=' then (obj) -> obj <= val
      when '>=' then (obj) -> obj >= val
      when '>'  then (obj) -> obj > val
      when '!=' then (obj) -> obj != val
      # `not` implementation when that makes sense:
      # when 'not'
      #   falseMatcher = _matcherOp val
      #   (obj) ->
      #     not falseMatcher obj

  # _matchAll: return a function that matches all matcher functions given
  _matchAll = (matchers) ->
    if matchers.length == 0
      return -> true
    else if matchers.length == 1
      return matchers[0]
    (obj) ->
      for matcher in matchers
        if not matcher obj
          return false
      true

  # _matcher returns a function that determines if the query matches
  _matcher = (query) ->
    # & case
    if _hasOnlyKey query, '&'
      matchers = _.map query['&'], _matcher
      return _matchAll matchers

    matchers = {}
    for path, expr of query
      do (path, expr) ->
        # Equality
        if not _.isObject expr
          matchers[path] = (obj) -> obj == expr
        else
          pathMatchers = []
          for op, val of expr
            pathMatchers.push (_matcherOp op, val, path)
          matchers[path] = _matchAll pathMatchers
    (obj) ->
      for path, matcher of matchers
        # console.log "path: ", path
        if not matcher(obj[path])
          # console.log "matcher failed: ", matcher
          return false
      true

  # queryfu.match
  # ----------------------------------------------------------------------------------------
  #     queryfu(age:'<=':4).match(name:'Evan', age:4)      # => true
  #     queryfu(age:'<':4).match(name:'Evan', age:4)       # => false

  # Determine if an object matches the query
  match: (obj) ->
    throw 'queryfu.match: Object expected for argument one' unless _.isObject obj
    @_match ?= _matcher @_query
    @_match obj

# CursorFu
# ----------------------------------------------------------------------------------------
#
# CursorFu(unbufferedCursor)
#
#     unbufferedCursor        Should have functions `next`, `hasNext`
#                             Optionally `all` or `toArray` will be used if they are defined

class CursorFu

  constructor: (@_cursor) ->
    throw 'CursorFu: Cursor expected for first argument' unless queryfu.isCursor @_cursor

  # next: Get next element
  next: ->
    throw 'CursorFu: next called on empty cursor' if not @hasNext()
    if @_rest
      return @_rest.shift
    @_cursor.next()

  # hasNext: Determine if there are more elements
  hasNext: ->
    return true if @_rest?.length
    @_cursor.hasNext()

  # count: Count remaining elements but keep position in stream
  count: ->
    if !@_rest
      @_rest = @_getRest()
    @_rest.length

  # all: Get all remaining elements as if calling next n times
  all: ->
    rest = if @_rest then @_rest else @_getRest()
    @_rest = []
    rest

  # toArray: Convert to array (alias of `all`)
  toArray: -> @all()

  # skip: Throw away up to n elements
  skip: (n) ->
    for i in [0...n]
      break unless @hasNext()
      @next()
    i

  # Private method to get everything and queue it
  _getRest: ->
    # Use all or toArray if they are implemented
    return @_cursor.all() if @_cursor.all?
    return @_cursor.toArray() if @_cursor.toArray?

    # Otherwise one at a time
    rest = []
    while @hasNext()
      rest.push @next()
    rest

# ### ListCursorFu

# Internal unbuffered cursor for lists

class ListCursorFu
  constructor: (list) ->
    throw 'ListCursorFu: Array expected for first argument (list)' unless _.isArray list
    @_list = list.slice 0

  next: ->
    @_list.shift()

  hasNext: ->
    @_list.length > 0

  all: ->
    rest = @_list
    @_list = []
    rest

# ### FilteredFu

# Internal unbuffered cursor for filtering

class FilteredFu
  constructor: (@_cursor, @_match) ->
    throw 'FilteredFu: Cursor expected for first argument (cursorToFilter)' unless queryfu.isCursor @_cursor
    throw 'FilteredFu: Function expected for second argument (matchFunction)' unless _.isFunction @_match

  next: ->
    next = if @_next? then @_next else @_getNext()
    @_next = undefined
    next

  hasNext: ->
    @_next = @_getNext() unless @_next
    not _.isUndefined @_next

  _getNext: ->
    while @_cursor.hasNext()
      next = @_cursor.next()
      if @_match next
        return next
    undefined

# queryfu.listCursor
# ----------------------------------------------------------------------------------------
#
# Create a list cursor from a list

queryfu.listCursor = (list) ->
  throw 'listCursor: Array expected for first argument' unless _.isArray list
  new CursorFu(new ListCursorFu list)

# queryfu.where
# ----------------------------------------------------------------------------------------
# Basic unit of querying. See `queryfu` for documentation as this is its alias.

queryfu.where = queryfu

# queryfu.isCursor
# ----------------------------------------------------------------------------------------
# Determine if object supports all cursor methods
#
# queryfu.isCursor(any, options)
#
#     any             Variable to check
#     options         (Optional) Object of options:
#       buffered      Check for all buffered methods      (default: false)
#
queryfu.isCursor = (any, options = {}) ->
  return false unless _.isObject any
  buffered = if options.buffered? then options.buffered else false
  isCursor = (_.isFunction any.next) and (_.isFunction any.hasNext)
  # Unbuffered cursor
  return isCursor unless buffered
  # Buffered cursor
  isBufferedCursor = isCursor and (_.isFunction any.all) and (_.isFunction any.count) and (_.isFunction any.skip)
# Export QueryFu
queryfu.QueryFu = QueryFu

# Export CursorFu
queryfu.CursorFu = CursorFu

# Version
queryfu.version = '0.2.0'

# Export
module.exports = queryfu