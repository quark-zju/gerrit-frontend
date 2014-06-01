@scrollTo = (element) ->
  if element
    element.scrollIntoView()
    # Note:
    # Setting `scrollTop` directly is okay, but Firefox and Chrome differs.
    # `body` works for Chrome, while `html` works for Firefox.
    # $('html, body').scrollTop($(element).offset().top)
