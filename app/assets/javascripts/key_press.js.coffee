{
  localStorage
  scrollTo
  updateLocationHash
} = @

NEXT_BOOKMARK_LINE_KEY = 'j'
PREV_BOOKMARK_LINE_KEY = 'k'
NEXT_BOOKMARK_COMMENT_KEY = 'J'
PREV_BOOKMARK_COMMENT_KEY = 'K'

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
    switch keyChar
      when NEXT_BOOKMARK_LINE_KEY, PREV_BOOKMARK_LINE_KEY
        jumpAmongElements $('.bookmarkLineNo'), keyChar == NEXT_BOOKMARK_LINE_KEY
      when NEXT_BOOKMARK_COMMENT_KEY, PREV_BOOKMARK_COMMENT_KEY
        jumpAmongElements $('.bookmarkComment'), keyChar == NEXT_BOOKMARK_COMMENT_KEY
