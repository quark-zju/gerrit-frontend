@WindowSizeMixin =
  # helper to include `editable`, `required` css classes
  handleWindowResize: ->
    @setState windowWidth: window.innerWidth, windowHeight: window.innerHeight

  componentWillMount: ->
    @handleWindowResize()

  componentDidMount: ->
    window.addEventListener 'resize', @handleWindowResize

  componentWillUnmount: ->
    window.removeEventListener 'resize', @handleWindowResize
