{div, span, table, code, tbody, thead, tr, td, i, input, li, ul, p, pre, br} = React.DOM

cx = React.addons.classSet
pullr = @pullr

LINES_BEFORE = 5
LINES_AFTER = 5
LINES_EXPAND_ONCE = 20

Line = React.createClass
  displayName: 'Line'

  render: ->
    props = @props
    span className: 'lineWrapper',
      span className: 'lineNo', props.lineNo
      pre className: 'code', props.content

MoreButton = React.createClass
  displayName: 'MoreButton'

  render: ->
    @transferPropsTo span className: 'lineWrapper',
      span className: 'moreButton', title: 'Press [SHIFT] and click to show all', 'Show More'


@DiffView = React.createClass
  displayName: 'DiffView'

  getInitialState: ->
    segmentExpanded: {}
    wholeDiffExpanded: false

  componentWillReceiveProps: (nextProps) ->
    # reset state if content is changed
    if nextProps.a != @props.a || nextProps.b != @props.b
      @setState @getInitialState()

  render: ->
    props = @props

    # calculate diff
    diffs = JsDiff.diffLines(props.a || '', props.b || '')

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

    # expand a segment
    expandLine = (lineNo, count = LINES_EXPAND_ONCE) =>
      segmentExpanded = @state.segmentExpanded
      segmentExpanded[lineNo] = (segmentExpanded[lineNo] || 0) + count
      @setState {segmentExpanded}

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
          Line key: j, lineNo: currentLineNo, content: s

    if segments.length == 1 && segments[0].class != 'insert' && !@state.wholeDiffExpanded
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
