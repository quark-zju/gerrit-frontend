# http://stackoverflow.com/questions/7616461/generate-a-hash-from-string-in-javascript-jquery
@hashString = (s) ->
  s.split('').reduce ((a, b) ->
    a = ((a << 5) - a) + b.charCodeAt(0)
    a & a
  ), 0
