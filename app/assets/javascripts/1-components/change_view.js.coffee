{a, div, span, table, tbody, thead, tr, td, i, input, li, ul, p, pre, h2, h3, sup, style, select, option} = React.DOM

cx = React.addons.classSet
{
  getLocationHash
  pullr
  pullw
  scrollTo
  updateLocationHash
} = @

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

INLINE_COMMENT_ID_PREFIX = 'inline-comment-'

detectLanguage = (pathname, content) ->
  # highlight.js's language detection is very poor. handle some common cases here.
  return 'python' if pathname.match(/\.py$/i) || content.match(/#!.*python/)
  return 'ini' if pathname.match(/\.conf$/i)
  # let highlight.js decide
  return null

FileDiff = React.createClass
  displayName: 'FileDiff'

  mixins: [JumpToIfHighlightMixin]

  shouldComponentUpdate: (nextProps, nextState) ->
    !_.isEqual(@props, nextProps) || !_.isEqual(@state, nextState)

  render: ->
    props = @props
    $a = props.a || ''
    $b = props.b || ''
    pathname = props.pathname

    div className: cx(fileDiff: true, highlight: props.highlight),
      h3 className: 'pathname', id: pathname, pathname
      DiffView {
        a: $a
        b: $b
        inlineComments: props.inlineComments
        highlightLine: props.highlightLine
        owner: props.owner
        highlightJsEnabled: (pathname != '/COMMIT_MSG')
        highlightJsLanguage: detectLanguage(pathname, $a)
      }

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
        highlightLine = props.highlight && props.highlight.type == 'line' && props.highlight.pathname == x && props.highlight.line
        FileDiff
          key: x
          pathname: x
          a: pullr(props.revisionA.files, x, props.revisionASide)
          b: pullr(props.revisionB.files, x, props.revisionBSide)
          inlineComments:
            a: props.revisionASide == 'b' && pullr(props.revisionA.files, x, 'comments')
            b: props.revisionBSide == 'b' && pullr(props.revisionB.files, x, 'comments')
          highlight: highlightLine == 0
          highlightLine: highlightLine
          owner: props.owner

InlineCommentPathname = React.createClass
  displayName: 'InlineCommentPathname'

  handleClick: ->
    props = @props
    revisionNumber = props.revisionNumber
    updateLocationHash P: props.pathname, L: 0, A: "#{revisionNumber}a", B: "#{revisionNumber}b", I: null

  render: ->
    pathname = @props.pathname
    span className: 'inlineCommentPathname', onClick: @handleClick, pathname

InlineComment = React.createClass
  displayName: 'InlineComment'

  mixins: [JumpToIfHighlightMixin]

  handleClick: ->
    props = @props
    revisionNumber = props.revisionNumber
    updateLocationHash P: props.pathname, L: props.lineNo, A: "#{revisionNumber}a", B: "#{revisionNumber}b", I: null

  render: ->
    props = @props
    span className: cx(inlineComment: true, highlight: props.highlight),
      span className: 'lineNo', id: "#{INLINE_COMMENT_ID_PREFIX}#{props.comment.id}", onClick: @handleClick, props.lineNo
      span className: 'inlineMessage', props.comment.message

InlineCommentList = React.createClass
  displayName: 'InlineCommentList'

  render: ->
    props = @props
    revisionNumber = props.revisionNumber

    div className: 'inlineCommentList',
      _(props.comments).map (fileComments, pathname) =>
        div key: pathname,
          InlineCommentPathname {pathname, revisionNumber}
          _(fileComments).map (comments, lineNo) ->
            comments.map (comment) -> InlineComment {
              key: lineNo
              # Firefox incorrectly decodeURIComponent location.hash, so test decoded id as well
              highlight: props.highlightInlineCommentId == comment.id || props.highlightInlineCommentId == decodeURIComponent(comment.id)
              revisionNumber
              pathname
              lineNo
              comment
            }

Comment = React.createClass
  displayName: 'Comment'

  getInitialState: ->
    # hide bot's comments by default
    collapsed: @isBot()

  shouldComponentUpdate: (nextProps, nextState) ->
    !_.isEqual(@props, nextProps) || !_.isEqual(@state, nextState)

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
              span null, props.message
              props.inlineComments && InlineCommentList comments: props.inlineComments, revisionNumber: props.revisionNumber, highlightInlineCommentId: props.highlightInlineCommentId

CommentList = React.createClass
  displayName: 'CommentList'

  shouldComponentUpdate: (nextProps) ->
    # only highlight may change
    !_.isEqual(@props.highlight, nextProps.highlight)

  componentWillMount: ->
    # assume that comments won't change (because ChangeView is top-level)
    # attach inline comments to standard comments only once
    props = @props
    comments = props.comments

    # step 0: prepare variables
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

    @commentIdToInlineComments = commentIdToInlineComments

  render: ->
    props = @props
    comments = props.comments
    commentIdToInlineComments = @commentIdToInlineComments

    # highlight?
    highlightInlineCommentId = props.highlight && props.highlight.type == 'inlineComment' && props.highlight.inlineCommentId

    div className: 'commentList',
      _.sortBy(comments, ((x) -> x.date)).map (comment) ->
        Comment $.extend(key: comment.id, inlineComments: commentIdToInlineComments[comment.id], owner: props.owner, highlightInlineCommentId: highlightInlineCommentId, comment)

MetaData = React.createClass
  displayName: 'MetaData'

  shouldComponentUpdate: (nextProps) ->
    !_.isEqual(@props, nextProps)

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

FileIndex = React.createClass
  displayName: 'FileIndex'

  getInitialState: ->
    top: null

  handleFileItemClick: (pathname, e) ->
    updateLocationHash P: pathname, L: 0, I: null

  handleMouseOver: (e) ->
    return if @state.top
    # calculate top that points to the selected file
    selectedPathname = getLocationHash()['P']
    pathnames = @props.pathnames
    selectedIndex = _.indexOf(pathnames, selectedPathname) || 0
    itemHeight = @refs.item0 && @refs.item0.getDOMNode().scrollHeight || 0
    paddingTop = 15
    top = e.clientY - (selectedIndex + 0.5) * itemHeight - paddingTop
    top = Math.min(window.innerHeight - @refs.list.getDOMNode().clientHeight, top)
    top = Math.max(top, 50)
    @setState {top}

  handleMouseLeave: (e) ->
    @setState top: null

  getStyle: ->
    state = @state
    props = @props
    if state.top?
      top: state.top
    else
      top: -5000

  render: ->
    selectedPathname = getLocationHash()['P']
    props = @props
    div className: 'fileIndexSidebar', onMouseOver: @handleMouseOver, onMouseLeave: @handleMouseLeave,
      div className: 'fileIndex', style: @getStyle(), ref: 'list',
        props.pathnames.map (pathname, index) =>
          pathSegments = pathname.split('/')
          itemProps = key: pathname, className: cx(fileItem: true, selected: selectedPathname == pathname), onClick: @handleFileItemClick.bind(this, pathname)
          itemProps.ref = 'item0' if index == 0
          div itemProps,
            span className: 'dirname', pathSegments[1..-2].join('/')
            span className: 'splitter', '/'
            span className: 'basename', pathSegments[-1..]

# Top-Level
@ChangeView = React.createClass
  displayName: 'ChangeView'

  componentWillMount: ->
    @handleLocationHashChange()
    return

  componentDidMount: ->
    window.addEventListener 'hashchange', @handleLocationHashChange, false
    return

  componentWillUnmount: ->
    window.removeEventListener 'hashchange', @handleLocationHashChange
    return

  getInitialState: ->
    revisionId = _.max(@props.revisions.map((x) -> x.revisionId))
    revisionA: {id: revisionId, side: 'a'}
    revisionB: {id: revisionId, side: 'b'}

  handleRevisionTagClick: (side, revision, e) ->
    newHash = {I: null, P: null, L: null}
    revisionToString = (revision) -> "#{revision.id}#{revision.side.toLowerCase()}"
    if e.shiftKey
      # fill two sides
      ['a', 'b'].forEach (side) ->
        newHash[side.toUpperCase()] = revisionToString id: revision.id, side: side
    else
      newHash[side] = revisionToString(revision)
    updateLocationHash newHash

  handleLocationHashChange: ->
    newState = highlight: {}
    props = @props
    hash = location.hash.replace(/^#/, '')
    line = null
    pathname = null
    elementId = null

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
          newState.highlight.type = 'line'
          newState.highlight.line ||= 0
          newState.highlight.pathname = value
        when 'L'
          newState.highlight.line = parseInt(value)
        when 'I'
          newState.highlight.type = 'inlineComment'
          newState.highlight.inlineCommentId = value

    @setState newState

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

    div className: 'changeView',
      if revisionAvailable
        RevisionSelector revisionIds: props.revisions.map((x) -> x.revisionId), revisionA: state.revisionA, revisionB: state.revisionB, onRevisionTagClick: @handleRevisionTagClick
      if props.notice
        p className: 'changeNotice notes', props.notice
      h2 className: 'sectionTitle', 'Metadata'
      MetaData @props
      h2 className: 'sectionTitle', 'Comments'
      CommentList comments: props.comments, revisions: props.revisions, owner: props.owner, highlight: state.highlight
      h2 className: 'sectionTitle', 'File Diffs'
      if revisionAvailable
        RevisionDiff {revisionA, revisionB, pathnames, revisionASide: state.revisionA.side, revisionBSide: state.revisionB.side, owner: props.owner, highlight: state.highlight}
      if revisionAvailable
        FileIndex {pathnames}

