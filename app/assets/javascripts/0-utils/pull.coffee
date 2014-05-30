# Get an element from an object using chained keys.
# Return null if some key doesn't exist.
#
# Example:
#
#   # Before
#   o.a && o.a.b && o.a.b.c
#
#   # After
#   pullr o, 'a', 'b', 'c'
#
@pullr = (object) ->
  for k in arguments
    continue if k == object || k == null
    object = object[k] if object
  object

# Get a (probably hash) element from an object using chained keys.
# Create empty object on demand.
#
# Example:
#
#   # Before
#   o.a ||= {}
#   o.a.b ||= {}
#   o.a.b.c
#
#   # After
#   pullw o, 'a', 'b', 'c'
#
@pullw = (object) ->
  for k in arguments
    continue if k == object || k == null
    object[k] ||= {}
    object = object[k]
  object
