{div, span, table, tbody, thead, tr, td, i, input, li, ul, p, pre, h2} = React.DOM

cx = React.addons.classSet
pullr = @pullr

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
    table className: 'revisionSelector',
      ['A', 'B'].map (j) ->
        tr className: "revision#{j}Selector", key: j,
          td className: 'revisionLabel', j
          props.revisionIds.map (x) ->
            ['a', 'b'].map (k) ->
              revision = props["revision#{j}"]
              td key: k, className: cx(
                revisionTag: true
                selected: x == revision.id && revision.side == k
                sideA: k == 'a'
                sideB: k == 'b'
              ), onClick: (->
                try props["onRevision#{j}Click"](id: x, side: k)
              ), "#{x}#{k}"

RevisionDiff = React.createClass
  displayName: 'RevisionDiff'

  render: ->
    props = @props
    div className: 'fileSetDiff',
      props.pathnames.map (x) ->
        FileDiff key: x, pathname: x, a: pullr(props.revisionA.files, x, props.revisionASide), b: pullr(props.revisionB.files, x, props.revisionBSide)

Comment = React.createClass
  displayName: 'Comment'

  render: ->
    props = @props
    div className: 'comment',
      div className: 'meta',
        Username className: 'author', user: props.author
        Timestamp className: 'date', time: props.date
      pre className: 'message', props.message
      div className: 'commentEnd'

CommentList = React.createClass
  displayName: 'CommentList'

  render: ->
    # TODO merge inline comments and change comments
    props = @props
    div className: 'commentList',
      _.sortBy(props.comments, ((x) -> x.date)).map (comment) ->
        Comment $.extend(key: comment.id, comment)

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
      CommentList comments: props.comments
      p className: 'changeId', @props.changeId
      p className: 'number', @props.number
      h2 className: 'sectionTitle', 'File Diffs'
      RevisionDiff {revisionA, revisionB, pathnames, revisionASide: state.revisionA.side, revisionBSide: state.revisionB.side}
