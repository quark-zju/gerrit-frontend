{div, span, table, tbody, thead, tr, td, i, input, li, ul, p, pre} = React.DOM

cx = React.addons.classSet
pullr = @pullr

@FileDiff = FileDiff = React.createClass
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


@RevisionView = RevisionView = React.createClass
  displayName: 'RevisionView'

  render: ->
    children = []
    for path, file of @props.files
      children.push(
        div key: path,
          p className: 'fileName', path
          FileView file
      )
    div className: 'revisionView', children

@RevisionSelector = RevisionSelector = React.createClass
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

@RevisionDiff = RevisionDiff = React.createClass
  displayName: 'revisionDiff'

  render: ->
    props = @props
    div className: 'fileSetDiff',
      props.pathnames.map (x) ->
        FileDiff key: x, pathname: x, a: pullr(props.revisionA.files, x, props.revisionASide), b: pullr(props.revisionB.files, x, props.revisionBSide)

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
      p className: 'changeId', @props.changeId
      p className: 'number', @props.number
      RevisionDiff {revisionA, revisionB, pathnames, revisionASide: state.revisionA.side, revisionBSide: state.revisionB.side}
      #@props.revisions.map (revision) ->
      #  div key: revision.revision_id,
      #    RevisionView revision
