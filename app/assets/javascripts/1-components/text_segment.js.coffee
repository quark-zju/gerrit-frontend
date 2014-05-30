{div, p, span, i, input, table, tr, td, br} = React.DOM

renderTextSegments = (content, tokenOffset = 0) ->
  # Find the first thing to be repalced
  token = ''
  tokenPosition = 1 / 0
  # <br>s
  position = content.indexOf '\n'
  if position >= 0 && position < tokenPosition
    tokenPosition = position
    token = '\n'
  if token == ''
    [span key: 'lastTextSegment', content]
  else if token == '\n' # <br>
    arr = [br key: "#{tokenOffset}a"]
    arr.unshift(span(key: "#{tokenOffset}b", content.substr(0, tokenPosition))) if tokenPosition > 0
    arr.concat(renderTextSegments(content.substr(tokenPosition + token.length), tokenOffset + token.length + tokenPosition))

@TextSegment = React.createClass
  displayName: 'TextSegment'
  render: ->
    # translates emojis, brs
    @transferPropsTo span className: 'textSegment',
      renderTextSegments(@props.content)
      @props.children
