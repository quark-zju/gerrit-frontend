{div, span, table, code, tbody, thead, tr, td, i, input, li, ul, p, pre, br} = React.DOM

cx = React.addons.classSet
{
  hashString
  pullr
  scrollTo
  updateLocationHash
} = @

LINES_BEFORE = 5
LINES_AFTER = 5
LINES_EXPAND_ONCE = 20

diffCache = {}

diffLines = (a, b) ->
  a ||= ''
  b ||= ''
  # make sure a, b ends with '\n'
  a += '\n' if a && a.length > 0 && a[a.length - 1] != '\n'
  b += '\n' if b && b.length > 0 && b[b.length - 1] != '\n'
  # cache diff results
  key = [hashString(a), a.length, hashString(b), b.length].join('_')
  diffCache[key] ||= JsDiff.diffLines(a, b)

Line = React.createClass
  displayName: 'Line'

  componentWillReceiveProps: (nextProps) ->
    if nextProps.highlight && !@props.highlight
      scrollTo @getDOMNode()

  render: ->
    props = @props
    span className: cx(lineWrapper: true, highlight: props.highlight),
      span className: 'lineNo', props.lineNo
      pre className: 'code', props.content
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
      TextSegment className: 'message', content: comment.message

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
    _.some ['a', 'b', 'highlightLine', 'bInlineComments'], (name) -> !_.isEqual(props[name], nextProps[name]) || !_.isEqual(@state, nextState)

  render: ->
    props = @props

    # calculate diff
    diffs = diffLines props.a, props.b

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
    props.bInlineComments && props.bInlineComments.forEach (comment) ->
      return unless comment && comment.line
      commentSet = (inlineCommentBySideLine.b[comment.line] ||= [])
      commentSet.push(comment)

    # render segment into lines
    renderSegmentLines = (segment, side) =>
      return null unless segment[side]
      lines = segment[side].split("\n")[0..-2]
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
          Line key: j, lineNo: currentLineNo, content: s, highlight: side == 'b' && props.highlightLine == currentLineNo,
            if (currentInlineComments = inlineCommentBySideLine[side][currentLineNo])
              currentInlineComments.map (comment) ->
                InlineComment key: comment.id, comment: comment, owner: props.owner

    if segments.length == 1 && segments[0].class == 'equal' && !@state.wholeDiffExpanded
      div className: 'diffView',
        MoreButton className: 'wholeDiffExpandButton', onClick: ((e) =>
          @setState wholeDiffExpanded: true, segmentExpanded: {0: if e.shiftKey then Infinity else 0}
        )
    else
      table className: 'diffView',
        tbody null,
          segments.map (segment) ->
            tr className: "diffSegment #{segment.class}", key: segment.id,
              td className: 'a',
                renderSegmentLines segment, 'a'
              td className: 'b',
                renderSegmentLines segment, 'b'
