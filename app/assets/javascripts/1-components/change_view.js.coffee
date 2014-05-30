{div, span, table, tbody, thead, tr, td, i, input, li, ul, p, pre, h2, sup} = React.DOM

cx = React.addons.classSet
pullr = @pullr
pullw = @pullw

@BOT_NAME_KEYWORDS = ['CI', 'Jenkins', 'jenkins', 'Neutron Ryu', 'Testing', 'OpenContrall', 'Recheck', 'LaunchpadSync', 'VMware']

FileDiff = React.createClass
  displayName: 'FileDiff'

  render: ->
    props = @props
    a = props.a
    b = props.b
    a += '\n' if a && a.length > 0 && a[a.length - 1] != '\n'
    b += '\n' if b && b.length > 0 && b[b.length - 1] != '\n'

    div className: 'fileDiff',
      p className: 'pathname', props.pathname
      DiffView {a, b}


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
        FileDiff key: x, pathname: x, a: pullr(props.revisionA.files, x, props.revisionASide), b: pullr(props.revisionB.files, x, props.revisionBSide)

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
              Username className: 'author', user: props.author
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

    for comment in comments
      authorDate = getCommentAuthorDate(comment)
      id = comment.id
      commentAuthorDateToId[authorDate] = id
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
        Comment $.extend(key: comment.id, inlineComments: commentIdToInlineComments[comment.id], comment)

@ChangeView = React.createClass
  displayName: 'ChangeView'

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
    pathnames = _.union(
      _(revisionA.files).keys()
      _(revisionB.files).keys()
    )

    div className: 'changeView',
      RevisionSelector revisionIds: props.revisions.map((x) -> x.revisionId), revisionA: state.revisionA, revisionB: state.revisionB, onRevisionBClick: @handleRevisionBClick, onRevisionAClick: @handleRevisionAClick
      h2 className: 'sectionTitle', 'Comments'
      CommentList comments: props.comments, revisions: props.revisions
      p className: 'changeId', @props.changeId
      p className: 'number', @props.number
      h2 className: 'sectionTitle', 'File Diffs'
      RevisionDiff {revisionA, revisionB, pathnames, revisionASide: state.revisionA.side, revisionBSide: state.revisionB.side}
