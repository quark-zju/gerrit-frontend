{div, span, table, code, tbody, thead, tr, td, i, input, li, ul, p, pre, br} = React.DOM

cx = React.addons.classSet
{
  hashString
  hljs
  pullr
  scrollTo
  updateLocationHash
} = @

LINES_BEFORE = 5
LINES_AFTER = 5
LINES_EXPAND_ONCE = 20

_diffCache = {}

diffLines = ($a, $b) ->
  $a ||= ''
  $b ||= ''
  # make sure a, b ends with '\n'
  $a += '\n' if $a && $a.length > 0 && $a[$a.length - 1] != '\n'
  $b += '\n' if $b && $b.length > 0 && $b[$b.length - 1] != '\n'
  # cache diff results
  key = [hashString($a), $a.length, hashString($b), $b.length].join('_')
  _diffCache[key] ||= JsDiff.diffLines($a, $b)


_highlightCache = {}

highlightJsRun = (code, language) ->
  return {} unless code?
  key = [hashString(code), code.length].join('_')
  _highlightCache[key] ||= (->
    resultLines = []
    html = ''
    try
      hljsResult =
        if language
          hljs.highlight(
            language
            code
            true # do not stop on syntax error
          )
        else
          hljs.highlightAuto(code)
      html = hljsResult.value

    parser = new DOMParser()
    root = parser.parseFromString(html, 'text/html').body
    resultLines = []
    currentLine = []
    pushCurrentLine = ->
      resultLines.push(currentLine)
      currentLine = []
    parseNode = (root, classPrefix = '') ->
      for node in root.childNodes
        type = node.className
        if node.childElementCount
          parseNode node, "#{classPrefix} #{type}"
        else # 0 or undefined
          content = node.textContent || node
          for text, index in content.split("\n")
            index > 0 && pushCurrentLine()
            data = {text}
            data.type = "#{classPrefix} #{type}" if type
            currentLine.push data
    # leading empty lines will be ignored by the DOM parser. add them back.
    position = 0
    while code[position] == '\n'
      pushCurrentLine()
      position += 1
    # start parse
    parseNode root
    pushCurrentLine()

    debugger
    [resultLines, hljsResult.language]
  )()

Line = React.createClass
  displayName: 'Line'

  mixins: [JumpToIfHighlightMixin]

  render: ->
    props = @props
    span className: cx(lineWrapper: true, highlight: props.highlight),
      span className: 'lineNo', props.lineNo
      span className: 'code',
        if props.hljsContent
          props.hljsContent.map (segment, index) ->
            span key: index, className: segment.type, segment.text
        else
          props.content
      props.children

MoreButton = React.createClass
  displayName: 'MoreButton'

  render: ->
    @transferPropsTo span className: 'lineWrapper',
      span className: 'moreButton', title: 'Hold [SHIFT] and click to show all', 'Show More'

InlineComment = React.createClass
  displayName: 'InlineComment'

  handleClick: ->
    updateLocationHash L: null, P: null, I: @props.comment.id

  render: ->
    props = @props
    comment = props.comment
    @transferPropsTo div className: 'inlineComment',
      Username className: cx(owner: comment.author.accountId == props.owner.accountId), user: comment.author, onClick: @handleClick
      span className: 'message', comment.message

@DiffView = React.createClass
  displayName: 'DiffView'

  getInitialState: ->
    segmentExpanded: {}
    wholeDiffExpanded: false

  componentWillReceiveProps: (nextProps) ->
    # reset state if content is changed
    if nextProps.a != @props.a || nextProps.b != @props.b
      @setState @getInitialState()

  shouldComponentUpdate: (nextProps, nextState) ->
    props = @props
    _.some ['a', 'b', 'highlightLine', 'inlineComments'], (name) -> !_.isEqual(props[name], nextProps[name]) || !_.isEqual(@state, nextState)

  render: ->
    props = @props

    # calculate diff
    diffs = diffLines props.a, props.b

    # highlight.js
    hljsLines = {a: [], b: []}
    hljsLanguage = 'python'
    if props.highlightJsEnabled
      for side in ['a',  'b']
        code = props[side]
        [hljsLines[side], hljsLanguage] = highlightJsRun code, props.highlightJsLanguage

    # covert diffs to side-by-side segments
    segments = []
    index = 0
    while (diff = diffs[index])
      if !diff.added && !diff.removed
        segments.push(class: 'equal', a: diff.value, b: diff.value, id: index)
      else if diff.added && (nextDiff = diffs[index + 1] || {}).removed
        segments.push(class: 'change', a: nextDiff.value, b: diff.value, id: index)
        index += 1
      else if diff.added
        segments.push(class: 'insert', a: null, b: diff.value, id: index)
      else if diff.removed
        segments.push(class: 'delete', a: diff.value, b: null, id: index)
      index += 1

    # line number counters
    lineNo = {a: 0, b: 0}

    # helper function: expand a segment
    expandLine = (lineNo, count = LINES_EXPAND_ONCE) =>
      segmentExpanded = @state.segmentExpanded
      segmentExpanded[lineNo] = (segmentExpanded[lineNo] || 0) + count
      @setState {segmentExpanded}

    # collect inline comments
    inlineCommentBySideLine = {a: {}, b: {}}
    for side, inlineComments of props.inlineComments || {}
      for comment in inlineComments || []
        return unless comment && comment.line
        commentSet = (inlineCommentBySideLine[side][comment.line] ||= [])
        commentSet.push(comment)

    # render segment into lines
    renderSegmentLines = (segment, side) =>
      return null unless segment[side]
      lines = segment[side].split("\n")[0..-2] # last line is always empty. remove it.
      baseLineNo = lineNo[side]
      linesExpanded = (@state.segmentExpanded[segment.id] || 0)
      linesBefore = LINES_BEFORE + linesExpanded
      linesAfter = LINES_AFTER + linesExpanded
      hide = lines.length > linesBefore + linesAfter && segment.class != 'insert'
      moreButtonDrawn = false
      lines.map (s, j) ->
        currentLineNo = (lineNo[side] += 1)
        relativeLineNo = currentLineNo - baseLineNo
        if hide && relativeLineNo > linesAfter && relativeLineNo < lines.length - linesBefore
          if moreButtonDrawn
            null
          else
            moreButtonDrawn = true
            MoreButton key: j, onClick: ((e) -> expandLine segment.id, if e.shiftKey then Infinity else LINES_EXPAND_ONCE)
        else
          Line key: j, lineNo: currentLineNo, content: s, hljsContent: hljsLines[side][currentLineNo - 1], highlight: side == 'b' && props.highlightLine == currentLineNo,
            if (currentInlineComments = inlineCommentBySideLine[side][currentLineNo])
              _(currentInlineComments).sortBy((c) -> c.date).map (comment) ->
                InlineComment key: comment.id, comment: comment, owner: props.owner

    if segments.length == 1 && segments[0].class == 'equal' && !@state.wholeDiffExpanded
      div className: "diffView #{hljsLanguage}",
        MoreButton className: 'wholeDiffExpandButton', onClick: ((e) =>
          @setState wholeDiffExpanded: true, segmentExpanded: {0: if e.shiftKey then Infinity else 0}
        )
    else
      table className: "diffView #{hljsLanguage}",
        tbody null,
          segments.map (segment) ->
            tr className: "diffSegment #{segment.class}", key: segment.id,
              td className: 'a',
                renderSegmentLines segment, 'a'
              td className: 'b',
                renderSegmentLines segment, 'b'
