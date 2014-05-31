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
  componentDidMount: ->
    if @props.highlight
      scrollTo @getDOMNode()

  componentWillReceiveProps: (nextProps) ->
    if nextProps.highlight && !@props.highlight
      scrollTo @getDOMNode()
