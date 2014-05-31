{a, div, span, table, tbody, thead, tr, td, i, input, li, ul, p, pre, h2, h3, sup, style} = React.DOM

Callbacks = @dpm.Callbacks.get()
cx = React.addons.classSet
pullr = @pullr
pullw = @pullw

@BOT_NAME_KEYWORDS = [
  'CI'
  'jenkins'
  'Jenkins'
  'LaunchpadSync'
  'Neutron Ryu'
  'OpenContrail'
  'OpenContrall'
  'Recheck'
  'SmokeStack'
  'Testing'
  'turbo-hipster'
  'VMware'
]

LOCATION_HASH_SPLITTER = ';'
LOCATION_HASH_KEY_VALUE_SPLITTER = ':'

getLocationHash = ->
  hash = location.hash.replace(/^#/, '')
  hashMap = {}
  for segment in hash.split(LOCATION_HASH_SPLITTER)
    [k, v] = segment.split(LOCATION_HASH_KEY_VALUE_SPLITTER)
    hashMap[k] = v
  hashMap

updateLocationHash = (newHashMap) ->
  return hash unless !_(newHashMap).isEmpty()
  hashMap = getLocationHash()
  $.extend hashMap, newHashMap
  newHash = []
  for k, v of hashMap
    if v && "#{v}".length > 0
      newHash.push "#{k}#{LOCATION_HASH_KEY_VALUE_SPLITTER}#{v}"
  newHash = newHash.join(LOCATION_HASH_SPLITTER)
  oldHash = location.hash.replace(/^#/, '')
  if oldHash != newHash
    location.hash = newHash
  newHash


FileDiff = React.createClass
  displayName: 'FileDiff'

  getInitialState: ->
    highlightLine: null

  componentDidMount: ->
    Callbacks.addCallback 'jumpToFileLine', this, 'handleJump'
    return

  componentWillUnmount: ->
    Callbacks.removeCallback 'jumpToFileLine', this, 'handleJump'
    return

  handleJump: (place) ->
    props = @props
    highlightLine =
      if place.pathname == props.pathname
        place.line
      else
        null
    @setState {highlightLine}

  render: ->
    props = @props
    $a = props.a
    $b = props.b
    $a += '\n' if $a && $a.length > 0 && $a[$a.length - 1] != '\n'
    $b += '\n' if $b && $b.length > 0 && $b[$b.length - 1] != '\n'

    div className: 'fileDiff',
      h3 className: 'pathname', id: props.pathname, props.pathname
      DiffView {a: $a, b: $b, bInlineComments: props.bInlineComments, highlightLine: @state.highlightLine}

RevisionTag = React.createClass
  displayName: 'RevisionTag'

  render: ->
    props = @props
    selectedRevision = props.selectedRevision
    revisionId = props.revisionId || selectedRevision.id
    revisionSide = props.revisionSide || selectedRevision.side

    td className: cx(
      revisionTag: true
      selected: revisionId == selectedRevision.id && selectedRevision.side == revisionSide
      sideA: revisionSide == 'a'
      sideB: revisionSide == 'b'
    ), title: 'Hold [SHIFT] and press to set both sides' , onClick: ((e) ->
      props.onClick && props.onClick({id: revisionId, side: revisionSide}, e)
    ),
      span null, revisionId
      sup null, revisionSide


RevisionSelector = React.createClass
  displayName: 'RevisionSelector'

  render: ->
    props = @props
    trs = []
    ['A', 'B'].map (selectorSide) ->
      _.eachSlice props.revisionIds, 12, (revisionIdSlice, index) ->
        trs.push(
          tr className: "revision#{selectorSide}Selector", key: "#{selectorSide}#{index}",
            if index == 0
              td className: 'revisionLabel', selectorSide
            else
              td null
            revisionIdSlice.map (revisionId) ->
              ['a', 'b'].map (revisionSide) ->
                selectedRevision = props["revision#{selectorSide}"]
                RevisionTag {key: "#{revisionId}_#{revisionSide}", selectedRevision, revisionId, revisionSide, onClick: ((r, e) -> props.onRevisionTagClick(selectorSide, r, e))}
        )
    div className: 'revisionSelector',
      table className: 'summaryTable',
        tbody null,
          tr null,
            ['A', 'B'].map (j) ->
              RevisionTag key: j, selectedRevision: props["revision#{j}"]
      table className: 'selectorTable',
        tbody null,
          trs

RevisionDiff = React.createClass
  displayName: 'RevisionDiff'

  render: ->
    props = @props
    div className: 'fileSetDiff',
      props.pathnames.map (x) ->
        FileDiff
          key: x
          pathname: x
          a: pullr(props.revisionA.files, x, props.revisionASide)
          b: pullr(props.revisionB.files, x, props.revisionBSide)
          bInlineComments: pullr(props.revisionB.files, x, 'comments')

InlineCommentPathname = React.createClass
  displayName: 'InlineCommentPathname'

  handleClick: ->
    Callbacks.fireCallback 'jumpTo', pathname: @props.pathname, revisionNumber: @props.revisionNumber, line: 1

  render: ->
    pathname = @props.pathname
    span className: 'inlineCommentFileName', onClick: @handleClick, pathname

InlineCommentList = React.createClass
  displayName: 'InlineCommentList'

  render: ->
    props = @props

    div className: 'inlineCommentList',
      _(props.comments).map (fileComments, pathname) =>
        div key: pathname,
          InlineCommentPathname pathname: pathname, revisionNumber: props.revisionNumber
          _(fileComments).map (comments, lineNo) =>
            comments.map (comment) =>
              span className: 'inlineComment',
                span className: 'lineNo', lineNo
                span className: 'inlineMessage', comment.message

Comment = React.createClass
  displayName: 'Comment'

  getInitialState: ->
    # hide bot's comments by default
    collapsed: @isBot()

  handleClick: ->
    if @state.collapsed
      @setState collapsed: !@state.collapsed

  isBot: ->
    _.find(BOT_NAME_KEYWORDS, (x) => @props.author.name.indexOf(x) >= 0) && true

  render: ->
    props = @props
    div className: cx(comment: true, collapsed: @state.collapsed, bot: @isBot()), id: "comment-#{props.id}", onClick: @handleClick,
      table className: 'commentTable',
        tbody null,
          tr null,
            td className: 'meta',
              Username className: cx(author: true, owner: props.author.accountId == props.owner.accountId), user: props.author
              Timestamp className: 'date', time: props.date
            td className: 'message',
              TextSegment content: props.message,
                props.inlineComments && InlineCommentList comments: props.inlineComments, revisionNumber: props.revisionNumber

CommentList = React.createClass
  displayName: 'CommentList'

  render: ->
    props = @props
    comments = props.comments

    # merge inline comments into normal comments (by author, date)
    commentAuthorDateToId = {}
    commentIdToInlineComments = {}
    getCommentAuthorDate = (comment) -> "#{comment.author.accountId}.#{Date.parse(comment.date)}"

    # step 1: index comment by author, date
    for comment in comments
      authorDate = getCommentAuthorDate(comment)
      id = comment.id
      commentAuthorDateToId[authorDate] = id

    # step 2: process inline comments
    for revision in props.revisions
      continue unless revision && revision.files
      for pathname, file of revision.files
        continue unless file && file.comments
        for inlineComment in file.comments
          authorDate = getCommentAuthorDate(inlineComment)
          commentId = commentAuthorDateToId[authorDate]
          fileComments = pullw commentIdToInlineComments, commentId, pathname
          (fileComments[inlineComment.line] ||= []).push(inlineComment)

    div className: 'commentList',
      _.sortBy(comments, ((x) -> x.date)).map (comment) ->
        Comment $.extend(key: comment.id, inlineComments: commentIdToInlineComments[comment.id], owner: props.owner, comment)

MetaData = React.createClass
  displayName: 'MetaData'
  render: ->
    props = @props
    trs = []
    _(['subject', 'changeId', 'owner', 'updatedAt', 'project', 'branch']).eachSlice 2, (slice) ->
      trs.push(
        tr key: slice[0], className: 'fieldRow',
          slice.map (field) ->
            [
              td key: "#{field}_n", className: 'fieldName', field
              td key: "#{field}_v", className: 'fieldValue',
                if field == 'owner'
                  Username user: props[field]
                else if field == 'changeId'
                  a href: "#{props.host.baseUrl}/#/c/#{props.number}/", target: '_blank', props[field]
                else
                  props[field]
            ]
      )
    table className: 'metaDataTable', trs


# Top-Level
@ChangeView = React.createClass
  displayName: 'ChangeView'

  mixins: [WindowSizeMixin]

  componentDidMount: ->
    window.addEventListener 'hashchange', @handleLocationHashChange, false
    Callbacks.addCallback 'jumpTo', this, 'handleJump'
    return

  componentWillUnmount: ->
    window.removeEventListener 'hashchange', @handleLocationHashChange
    Callbacks.removeCallback 'jumpTo', this, 'handleJump'
    return

  getInitialState: ->
    revisionId = _.max(@props.revisions.map((x) -> x.revisionId))
    revisionA: {id: revisionId, side: 'a'}
    revisionB: {id: revisionId, side: 'b'}

  handleRevisionTagClick: (side, revision, e) ->
    state = {}
    state["revision#{side}"] = revision
    if e.shiftKey
      # fill two sides
      ['a', 'b'].forEach (side) ->
        state["revision#{side.toUpperCase()}"] = {
          id: revision.id
          side: side
        }
    @setState state

  handleLocationHashChange: ->
    newState = {}
    props = @props
    hash = location.hash.replace(/^#/, '')
    jumpToFile = {}

    # do not proceed if hash is not changed
    return if hash == @lastLocationHash
    @lastLocationHash = hash

    for key, value of getLocationHash()
      switch key
        when 'A', 'B'
          revisionId = parseInt(value)
          revisionSide = value[-1..-1].toLowerCase()
          if _.find(props.revisions, (x) -> x.revisionId == revisionId)
            newState["revision#{key}"] =
              id: revisionId
              side: revisionSide
        when 'P' # pathname, one time
          1

    if !_(newState).isEmpty()
      @setState newState

  handleJump: (place) ->
    hashMap = {}
    hashMap['L'] = line = place.line
    hashMap['P'] = pathname = place.pathname
    if place.revisionNumber
      hashMap['A'] = "#{place.revisionNumber}a"
      hashMap['B'] = "#{place.revisionNumber}b"
    return if _(hashMap).isEmpty()
    updateLocationHash hashMap
    if line && pathname
      # redraw all so that selected revision / file is displayed
      @forceUpdate()
      # jump to selected line
      Callbacks.fireCallback 'jumpToFileLine', {line, pathname}

  setLocationHash: ->
    state = @state
    hashMap = {}
    # append revision information
    ['A', 'B'].forEach (side) ->
      revision = state["revision#{side}"]
      if revision.id >= 0
        hashMap[side] = "#{revision.id}#{revision.side}"
    @lastLocationHash = updateLocationHash hashMap

  render: ->
    props = @props
    state = @state
    revisionA = _.find(props.revisions, (x) -> x.revisionId == state.revisionA.id)
    revisionB = _.find(props.revisions, (x) -> x.revisionId == state.revisionB.id)
    revisionAvailable = revisionA && revisionB
    pathnames = if revisionAvailable
      _.union(
        _(revisionA.files).keys()
        _(revisionB.files).keys()
      )
    else
      []

    @setLocationHash()

    div className: 'changeView',
      style null, ".diffSegment .lineWrapper{max-width: #{Math.max(100, state.windowWidth / 2 - 28)}px}"
      if revisionAvailable
        RevisionSelector revisionIds: props.revisions.map((x) -> x.revisionId), revisionA: state.revisionA, revisionB: state.revisionB, onRevisionTagClick: @handleRevisionTagClick
      if props.notice
        p className: 'changeNotice notes', props.notice
      h2 className: 'sectionTitle', 'Metadata'
      MetaData @props
      h2 className: 'sectionTitle', 'Comments'
      CommentList comments: props.comments, revisions: props.revisions, owner: props.owner
      h2 className: 'sectionTitle', 'File Diffs'
      if revisionAvailable
        RevisionDiff {revisionA, revisionB, pathnames, revisionASide: state.revisionA.side, revisionBSide: state.revisionB.side}
