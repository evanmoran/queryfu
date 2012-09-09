queryfu
====================================================================
An intermediate query language for ninjas. Write your query once. Use it in any system.

### Usage

There are four pretty similar ways to use queryfu:

#### queryfu(path, value)

    path                String of attribute with optional dot syntax (e.g. 'name', 'person.name')
    value               String, Number, Boolean, Date, or null that defines value being compared

#### queryfu(path, operator, value)

    path                String of attribute with optional dot syntax (e.g. 'name', 'person.name')
    value               String, Number, Boolean, Date, or null that defines value being compared
    operator            (Default: '=') String representing operator:  <, <=, =, >=, >, !=

#### queryfu(pathValue)

    pathValue           Object that maps path to value (age: 5)

#### queryfu(pathOperatorValue)

    pathOperatorValue   Object that maps path to operator to value (age:'<':5)

 Basics

    queryfu(age, 4).toJSON()                            # => {age:4}
    queryfu(age:4).toJSON()                             # => {age:4}
    queryfu('age', '<=', 4).toJSON()                    # => {age:{'<=':4}}
    queryfu(age:'<=':4).toJSON()                        # => {age:{'<=':4}}
    queryfu(age:'<=':4).and(height:'>=':10).toJSON()    # => {age:{'<=':4}, height:{'>':10}}

 Match

    queryfu(age:'<=':4).match(name:'Evan', age:4)       # => true
    queryfu(age:'<':4).match(name:'Evan', age:4)        # => false

 Mongo

    queryfu(age:'<':4).toMongo()                        # => {age:{'$lt':4}}
    queryfu(age:'<':4).and(height:'>=':10).toMongo()    # => {age:{'$lt':4, '$gte':10}}