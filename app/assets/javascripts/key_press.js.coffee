{
  localStorage
  scrollTo
  updateLocationHash
} = @

NEXT_BOOKMARK_LINE_KEYS = [']', 'n']
PREV_BOOKMARK_LINE_KEYS = ['[', 'p']
NEXT_BOOKMARK_COMMENT_KEYS = ['c', 'N']
PREV_BOOKMARK_COMMENT_KEYS = ['P']

jumpAmongElements = (elements, isNext) ->
  scrollY = window.scrollY
  for element in elements
    y = $(element).offset().top
    if isNext && !target && y > scrollY
      target = element
    else if !isNext && y < scrollY
      target = element
  if !target
    target =
      if isNext
        _(elements).first()
      else
        _(elements).last()
  scrollTo target


$ ->
  $(document).keypress (e) ->
    # Firefox uses `key`, Chrome uses `keyCode`.
    keyChar = e.key || String.fromCharCode(e.keyCode)
    if NEXT_BOOKMARK_LINE_KEYS.concat(PREV_BOOKMARK_LINE_KEYS).indexOf(keyChar) > -1
      jumpAmongElements $('.bookmarkLineNo'), NEXT_BOOKMARK_LINE_KEYS.indexOf(keyChar) > -1
    else if NEXT_BOOKMARK_COMMENT_KEYS.concat(PREV_BOOKMARK_COMMENT_KEYS).indexOf(keyChar) > -1
      jumpAmongElements $('.bookmarkComment'), NEXT_BOOKMARK_COMMENT_KEYS.indexOf(keyChar) > -1
