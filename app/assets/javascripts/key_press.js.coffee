{
  localStorage
  scrollTo
  updateLocationHash
} = @

NEXT_BOOKMARK_LINE_KEY = 'j'
PREV_BOOKMARK_LINE_KEY = 'k'

$ ->
  $(document).keypress (e) ->
    keyChar = String.fromCharCode(e.keyCode)

    switch keyChar
      when NEXT_BOOKMARK_LINE_KEY, PREV_BOOKMARK_LINE_KEY
        # cycle all bookmarkLineNos
        bookmarks = $('.bookmarkLineNo')
        scrollY = window.scrollY
        target = null
        for element in bookmarks
          y = $(element).offset().top
          if keyChar == NEXT_BOOKMARK_LINE_KEY && !target && y > scrollY
            target = element
          else if keyChar == PREV_BOOKMARK_LINE_KEY && y < scrollY
            target = element
        if !target
          target =
            if keyChar == NEXT_BOOKMARK_LINE_KEY
              bookmarks[0]
            else
              bookmarks.last()[0]
        scrollTo target
