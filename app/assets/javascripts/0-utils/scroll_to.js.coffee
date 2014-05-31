@scrollTo = (element) ->
  if element
    document.body.scrollTop = $(element).offset().top
