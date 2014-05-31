{a, div, span, table, tbody, thead, tr, td, i, input, li, ul, p, pre, h2, sup, style} = React.DOM

cx = React.addons.classSet
pullr = @pullr
pullw = @pullw

@BOT_NAME_KEYWORDS = ['CI', 'Jenkins', 'jenkins', 'Neutron Ryu', 'Testing', 'OpenContrall', 'Recheck', 'LaunchpadSync', 'VMware', 'OpenContrail']

FileDiff = React.createClass
  displayName: 'FileDiff'

  render: ->
    props = @props
    $a = props.a
    $b = props.b
    $a += '\n' if $a && $a.length > 0 && $a[$a.length - 1] != '\n'
    $b += '\n' if $b && $b.length > 0 && $b[$b.length - 1] != '\n'

    div className: 'fileDiff',
      p className: 'pathname', props.pathname
      DiffView {a: $a, b: $b, bInlineComments: props.bInlineComments}


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
                td key: "#{revisionId}_#{revisionSide}", className: cx(
                  revisionTag: true
                  selected: revisionId == selectedRevision.id && selectedRevision.side == revisionSide
                  sideA: revisionSide == 'a'
                  sideB: revisionSide == 'b'
                ), onClick: (->
                  try props["onRevision#{selectorSide}Click"](id: revisionId, side: revisionSide)
                ),
                  span null, revisionId
                  sup null, revisionSide
        )
    div className: 'revisionSelector',
      table className: 'summaryTable',
        tbody null,
          tr null,
            ['A', 'B'].map (j) ->
              td key: "#{j}_1", className: 'revisionTag selected', props["revision#{j}"]
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

InlineComments = React.createClass
  displayName: 'InlineComments'

  render: ->
    props = @props

    div className: 'inlineCommentList',
      _(props.inlineComments).map (fileComments, pathname) =>
        div key: pathname,
          span className: 'inlineCommentFileName', pathname
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
                props.inlineComments && InlineComments inlineComments: props.inlineComments

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

@ChangeView = React.createClass
  displayName: 'ChangeView'

  mixins: [WindowSizeMixin]

  getInitialState: ->
    revisionId = _.max(@props.revisions.map((x) -> x.revisionId))
    revisionA: {id: revisionId, side: 'a'}
    revisionB: {id: revisionId, side: 'b'}

  handleRevisionAClick: (id) ->
    @setState revisionA: id

  handleRevisionBClick: (id) ->
    @setState revisionB: id

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
      style null, ".diffSegment .lineWrapper{max-width: #{Math.max(100, state.windowWidth / 2 - 28)}px}"
      if revisionAvailable
        RevisionSelector revisionIds: props.revisions.map((x) -> x.revisionId), revisionA: state.revisionA, revisionB: state.revisionB, onRevisionBClick: @handleRevisionBClick, onRevisionAClick: @handleRevisionAClick
      if props.notice
        p className: 'changeNotice notes', "Note: #{props.notice}"
      h2 className: 'sectionTitle', 'Metadata'
      MetaData @props
      h2 className: 'sectionTitle', 'Comments'
      CommentList comments: props.comments, revisions: props.revisions, owner: props.owner
      h2 className: 'sectionTitle', 'File Diffs'
      if revisionAvailable
        RevisionDiff {revisionA, revisionB, pathnames, revisionASide: state.revisionA.side, revisionBSide: state.revisionB.side}
