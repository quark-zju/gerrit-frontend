# http://stackoverflow.com/questions/10249658/equivalent-of-ruby-enumerableeach-slice-in-javascript
_.mixin eachSlice: (obj, size, iterator, context) ->
  i = 0
  l = obj.length
  while i < l
    iterator.call context, obj.slice(i, i + size), i, obj
    i += size
  return
