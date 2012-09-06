
# queryfu
# ====================================================================
# An intermediate query language for ninjas.

# queryfu(path, value)
# queryfu(path, operator, value)
# ----------------------------------------------------------------------------------------
#
#     path          String of attribute with optional dot syntax (e.g. 'name', 'person.name')
#     value         String, Number, Boolean, Date, or null that defines value being compared
#     operator      (Optional) String representing operator:
#                   <, <=, =, >=, >, !=
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

_mergeOpAtQuery = (query) ->
  # Check for &

  # loop to find merges


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
    # TODO: validation of json
    @_query = _.clone json
    @_errors = errors.slice 0

  _inplaceWhere: (path, operator, value) ->
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

# The queryfu function is where
queryfu.where = queryfu

# queryfu = module.exports
queryfu.version = '0.0.1'

module.exports = queryfu