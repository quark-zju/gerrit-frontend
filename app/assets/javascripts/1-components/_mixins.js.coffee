@WindowSizeMixin =
  handleWindowResize: ->
    @setState windowWidth: window.innerWidth, windowHeight: window.innerHeight

  componentWillMount: ->
    @handleWindowResize()

  componentDidMount: ->
    window.addEventListener 'resize', @handleWindowResize

  componentWillUnmount: ->
    window.removeEventListener 'resize', @handleWindowResize

scrollTo = @scrollTo

@JumpToIfHighlightMixin =
  scrollToSelf: ->
    # there may be some pending layouting work.
    # use setTimeout to defer the actural scrollTo.
    setTimeout((=> scrollTo @getDOMNode()), 1)

  componentDidMount: ->
    if @props.highlight
      @scrollToSelf()

  componentWillReceiveProps: (nextProps) ->
    if nextProps.highlight && !@props.highlight
      @scrollToSelf()
