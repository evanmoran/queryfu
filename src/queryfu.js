// Generated by CoffeeScript 1.3.3
(function() {
  var CursorFu, ListCursorFu, MappedFu, QueryFu, bufferCursor, queryfu, root, unbufferedFilterCursor, unbufferedMapCursor, _, _hasOnlyKey, _isArrayEqual, _mergeFailed, _mergeOp;

  _ = require('underscore');

  queryfu = function(path, operator, value) {
    var qf;
    qf = new QueryFu;
    return qf.where.apply(qf, arguments);
  };

  root = this;

  _isArrayEqual = function(arr1, arr2) {
    var k, v, _i, _len;
    if (arr1.length !== arr2.length) {
      return false;
    }
    for (k = _i = 0, _len = arr1.length; _i < _len; k = ++_i) {
      v = arr1[k];
      if (arr2[k] !== v) {
        return false;
      }
    }
    return true;
  };

  _hasOnlyKey = function(obj, key) {
    return (_.isObject(obj)) && _isArrayEqual(_.keys(obj), [key]);
  };

  _mergeFailed = {};

  _mergeOp = function(operator, currentValue, value, key, errorList) {
    switch (operator) {
      case '<':
      case '<=':
        return Math.min(value, currentValue);
      case '>=':
      case '>':
        return Math.max(value, currentValue);
      case '=':
        if (currentValue !== value) {
          errorList.push("conflicting equality checks were found (key: " + key + ", values: " + currentValue + ", " + value + ")");
        }
        return value;
    }
    return _mergeFailed;
  };

  queryfu.QueryFu = QueryFu = (function() {
    var _exprToMongo, _matchAll, _matcher, _matcherOp, _toMongoOp;

    function QueryFu(json, errors) {
      if (json == null) {
        json = {};
      }
      if (errors == null) {
        errors = [];
      }
      this._query = _.clone(json);
      this._errors = errors.slice(0);
      this._match = null;
    }

    QueryFu.prototype._inplaceWhere = function(path, operator, value) {
      var expr, expression, k, merged, subquery, v;
      this._match = null;
      if (arguments.length === 1 && _.isObject(path)) {
        for (k in path) {
          v = path[k];
          this._inplaceWhere(k, v);
        }
        return this;
      }
      if (arguments.length === 2) {
        if (_.isObject(operator)) {
          for (k in operator) {
            v = operator[k];
            this._inplaceWhere(path, k, v);
          }
          return this;
        }
        value = operator;
        operator = '=';
      }
      if (operator === '==') {
        operator = '=';
      }
      if ((expr = this._query[path]) != null) {
        if (!_.isObject(expr)) {
          expr = (this._query[path] = {
            '=': expr
          });
        }
        if (!(expr[operator] != null)) {
          expr[operator] = value;
        } else {
          merged = _mergeOp(operator, this._query[path][operator], value, path, this._errors);
          if (merged !== _mergeFailed) {
            this._query[path][operator] = merged;
            if (_hasOnlyKey(this._query[path], '=')) {
              this._query[path] = this._query[path]['='];
            }
          } else {
            subquery = {};
            subquery[path] = {};
            subquery[path][operator] = value;
            this._query = {
              '&': [this._query, subquery]
            };
          }
        }
      } else {
        switch (operator) {
          case '=':
          case '==':
            this._query[path] = value;
            break;
          case '!=':
          case '<':
          case '<=':
          case '>=':
          case '>':
            expression = {};
            expression[operator] = value;
            this._query[path] = expression;
        }
      }
      return this;
    };

    QueryFu.prototype.where = function() {
      var q;
      q = new QueryFu(this._query, this._errors);
      return q._inplaceWhere.apply(q, arguments);
    };

    QueryFu.prototype.and = function() {
      return this.where.apply(this, arguments);
    };

    QueryFu.prototype.error = function() {
      return this._errors.join('\n');
    };

    QueryFu.prototype.toJSON = function() {
      return this._query;
    };

    _toMongoOp = function(op, value) {
      var answer, opMap;
      answer = {};
      opMap = {
        '<': '$lt',
        '>': '$gt',
        '<=': '$lte',
        '>=': '$gte'
      };
      if (opMap[op] != null) {
        answer[opMap[op]] = value;
      } else if (op === '!=') {
        answer['$not'] = value;
      }
      return answer;
    };

    _exprToMongo = function(expr) {
      var mongoExpr, op, val;
      if (_.isObject(expr)) {
        mongoExpr = {};
        for (op in expr) {
          val = expr[op];
          _.extend(mongoExpr, _toMongoOp(op, val));
        }
        return mongoExpr;
      } else {
        return expr;
      }
    };

    QueryFu.prototype.toMongo = function(query) {
      var equalities, expr, mongo, path;
      if (query == null) {
        query = this._query;
      }
      if (_hasOnlyKey(query, '&')) {
        return {
          '$and': _.map(query['&'], this.toMongo)
        };
      }
      mongo = {};
      equalities = {};
      for (path in query) {
        expr = query[path];
        mongo[path] = _exprToMongo(expr);
        if (expr['='] != null) {
          equalities[path] = expr['='];
        }
      }
      if ((_.keys(equalities)).length) {
        mongo = {
          '$and': [mongo, this.toMongo(equalities)]
        };
      }
      return mongo;
    };

    QueryFu.prototype.select = function(cursorOrArray) {
      var cursor;
      if (!((_.isArray(cursorOrArray)) || (queryfu.isCursor(cursorOrArray)))) {
        throw 'queryfu.select: Cursor or array expected for argument one';
      }
      cursor = _.isArray(cursorOrArray) ? queryfu.listCursor(cursorOrArray) : cursorOrArray;
      return queryfu.filterCursor(cursor, _.bind(this.match, this));
    };

    _matcherOp = function(op, val, path) {
      if (path == null) {
        path = '';
      }
      switch (op) {
        case '=':
          return function(obj) {
            return obj === val;
          };
        case '<':
          return function(obj) {
            return obj < val;
          };
        case '<=':
          return function(obj) {
            return obj <= val;
          };
        case '>=':
          return function(obj) {
            return obj >= val;
          };
        case '>':
          return function(obj) {
            return obj > val;
          };
        case '!=':
          return function(obj) {
            return obj !== val;
          };
      }
    };

    _matchAll = function(matchers) {
      if (matchers.length === 0) {
        return function() {
          return true;
        };
      } else if (matchers.length === 1) {
        return matchers[0];
      }
      return function(obj) {
        var matcher, _i, _len;
        for (_i = 0, _len = matchers.length; _i < _len; _i++) {
          matcher = matchers[_i];
          if (!matcher(obj)) {
            return false;
          }
        }
        return true;
      };
    };

    _matcher = function(query) {
      var expr, matchers, path, _fn;
      if (_hasOnlyKey(query, '&')) {
        matchers = _.map(query['&'], _matcher);
        return _matchAll(matchers);
      }
      matchers = {};
      _fn = function(path, expr) {
        var op, pathMatchers, val;
        if (!_.isObject(expr)) {
          return matchers[path] = function(obj) {
            return obj === expr;
          };
        } else {
          pathMatchers = [];
          for (op in expr) {
            val = expr[op];
            pathMatchers.push(_matcherOp(op, val, path));
          }
          return matchers[path] = _matchAll(pathMatchers);
        }
      };
      for (path in query) {
        expr = query[path];
        _fn(path, expr);
      }
      return function(obj) {
        var matcher;
        for (path in matchers) {
          matcher = matchers[path];
          if (!matcher(obj[path])) {
            return false;
          }
        }
        return true;
      };
    };

    QueryFu.prototype.match = function(obj) {
      var _ref;
      if (!_.isObject(obj)) {
        throw 'queryfu.match: Object expected for argument one';
      }
      if ((_ref = this._match) == null) {
        this._match = _matcher(this._query);
      }
      return this._match(obj);
    };

    return QueryFu;

  })();

  queryfu.CursorFu = CursorFu = (function() {

    function CursorFu(_cursor) {
      this._cursor = _cursor;
      if (!queryfu.isCursor(this._cursor)) {
        throw 'CursorFu: Cursor expected for first argument';
      }
    }

    CursorFu.prototype.next = function() {
      if (!this.hasNext()) {
        throw 'CursorFu: next called on empty cursor';
      }
      if (this._rest) {
        return this._rest.shift;
      }
      return this._cursor.next();
    };

    CursorFu.prototype.hasNext = function() {
      var _ref;
      if ((_ref = this._rest) != null ? _ref.length : void 0) {
        return true;
      }
      return this._cursor.hasNext();
    };

    CursorFu.prototype.count = function() {
      if (!this._rest) {
        this._rest = this._getRest();
      }
      return this._rest.length;
    };

    CursorFu.prototype.all = function() {
      var rest;
      rest = this._rest ? this._rest : this._getRest();
      this._rest = [];
      return rest;
    };

    CursorFu.prototype.toArray = function() {
      return this.all();
    };

    CursorFu.prototype.skip = function(n) {
      var i, _i;
      for (i = _i = 0; 0 <= n ? _i < n : _i > n; i = 0 <= n ? ++_i : --_i) {
        if (!this.hasNext()) {
          break;
        }
        this.next();
      }
      return i;
    };

    CursorFu.prototype._getRest = function() {
      var rest;
      if (this._cursor.all != null) {
        return this._cursor.all();
      }
      if (this._cursor.toArray != null) {
        return this._cursor.toArray();
      }
      rest = [];
      while (this.hasNext()) {
        rest.push(this.next());
      }
      return rest;
    };

    return CursorFu;

  })();

  ListCursorFu = (function() {

    function ListCursorFu(list) {
      if (!_.isArray(list)) {
        throw 'ListCursorFu: Array expected for first argument (list)';
      }
      this._list = list.slice(0);
    }

    ListCursorFu.prototype.next = function() {
      return this._list.shift();
    };

    ListCursorFu.prototype.hasNext = function() {
      return this._list.length > 0;
    };

    ListCursorFu.prototype.all = function() {
      var rest;
      rest = this._list;
      this._list = [];
      return rest;
    };

    return ListCursorFu;

  })();

  bufferCursor = function(cursor) {
    if (!cursor) {
      return null;
    }
    if (queryfu.isCursor(cursor, {
      buffered: true
    })) {
      return cursor;
    } else {
      return new CursorFu(cursor);
    }
  };

  unbufferedMapCursor = function(cursor, transform) {
    if (!cursor) {
      return null;
    }
    return new MappedFu(cursor, transform);
  };

  queryfu.mapCursor = function(cursor, transform) {
    return bufferCursor(unbufferedMapCursor(cursor, transform));
  };

  unbufferedFilterCursor = function(cursor, filter) {
    return unbufferedMapCursor(cursor, function(elem) {
      if (filter(elem)) {
        return elem;
      } else {
        return void 0;
      }
    });
  };

  queryfu.filterCursor = function(cursor, filter) {
    return bufferCursor(unbufferedFilterCursor(cursor, filter));
  };

  MappedFu = (function() {

    function MappedFu(_cursor, _map) {
      this._cursor = _cursor;
      this._map = _map;
      if (!queryfu.isCursor(this._cursor)) {
        throw 'MappedFu: Cursor expected for first argument (cursorToMap)';
      }
      if (!_.isFunction(this._map)) {
        throw 'MappedFu: Function expected for second argument (mapFunction)';
      }
      this._next = void 0;
    }

    MappedFu.prototype.next = function() {
      var next;
      next = !_.isUndefined(this._next) ? this._next : this._getNext();
      this._next = void 0;
      return next;
    };

    MappedFu.prototype.hasNext = function() {
      if (_.isUndefined(this._next)) {
        this._next = this._getNext();
      }
      return !_.isUndefined(this._next);
    };

    MappedFu.prototype._getNext = function() {
      var mapped, next;
      while (this._cursor.hasNext()) {
        next = this._cursor.next();
        mapped = this._map(next);
        if (!_.isUndefined(mapped)) {
          return mapped;
        }
      }
      return void 0;
    };

    return MappedFu;

  })();

  queryfu.listCursor = function(list) {
    if (!_.isArray(list)) {
      throw 'listCursor: Array expected for first argument';
    }
    return bufferCursor(new ListCursorFu(list));
  };

  queryfu.where = queryfu;

  queryfu.isCursor = function(obj, options) {
    var buffered, isBufferedCursor, isCursor;
    if (options == null) {
      options = {};
    }
    if (!_.isObject(obj)) {
      return false;
    }
    buffered = options.buffered != null ? options.buffered : false;
    isCursor = (_.isFunction(obj.next)) && (_.isFunction(obj.hasNext));
    if (!buffered) {
      return isCursor;
    }
    return isBufferedCursor = isCursor && (_.isFunction(obj.all)) && (_.isFunction(obj.count)) && (_.isFunction(obj.skip));
  };

  queryfu.version = '0.2.3';

  module.exports = queryfu;

}).call(this);
