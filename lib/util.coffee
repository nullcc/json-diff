
extendedTypeOf = (obj) ->
  result = typeof obj
  if !obj?
    'null'
  else if result is 'object' and obj.constructor is Array
    'array'
  else
    result

isIntNumber = (number) ->
  ~~number == number

module.exports = { extendedTypeOf, isIntNumber }
