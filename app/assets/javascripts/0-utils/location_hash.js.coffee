LOCATION_HASH_SPLITTER = ';'
LOCATION_HASH_KEY_VALUE_SPLITTER = ':'

@getLocationHash = ->
  hash = location.hash.replace(/^#/, '')
  hashMap = {}
  for segment in hash.split(LOCATION_HASH_SPLITTER)
    [k, v] = segment.split(LOCATION_HASH_KEY_VALUE_SPLITTER)
    hashMap[k] = v
  hashMap

@updateLocationHash = (newHashMap) ->
  return hash unless !_(newHashMap).isEmpty()
  hashMap = getLocationHash()
  $.extend hashMap, newHashMap
  newHash = []
  for k, v of hashMap
    if v? && "#{v}".length > 0
      newHash.push "#{k}#{LOCATION_HASH_KEY_VALUE_SPLITTER}#{v}"
  newHash = newHash.join(LOCATION_HASH_SPLITTER)
  oldHash = location.hash.replace(/^#/, '')
  if oldHash != newHash
    location.hash = newHash
  newHash

