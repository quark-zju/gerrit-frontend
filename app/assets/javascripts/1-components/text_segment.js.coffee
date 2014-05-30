{div, p, span, i, input, table, tr, td, br} = React.DOM

renderTextSegments = (content, tokenOffset = 0) ->
  # Find the first thing to be repalced
  token = null
  tokenPosition = 1 / 0

  # <br>, space
  ['\n'].forEach (currentToken) ->
    position = content.indexOf currentToken
    if position >= 0 && position < tokenPosition
      tokenPosition = position
      token = currentToken

  if !token
    result = [span key: 'lastTextSegment', content]
  else if token == ' ' # space, seems not useful
    result = [span key: "#{tokenOffset}s", ' ']
  else if token == '\n' # <br>
    result = [br key: "#{tokenOffset}a"]

  if token
    result.unshift(span(key: "#{tokenOffset}b", content.substr(0, tokenPosition))) if tokenPosition > 0
    result = result.concat(renderTextSegments(content.substr(tokenPosition + token.length), tokenOffset + token.length + tokenPosition))

  result

@TextSegment = React.createClass
  displayName: 'TextSegment'
  render: ->
    # translates emojis, brs
    @transferPropsTo span className: 'textSegment',
      renderTextSegments(@props.content)
      @props.children
