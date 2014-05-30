{span} = React.DOM

RELATIVE_TIME_WITHIN_THRESHOLD = 1000 * 60 * 60 * 24 * 5 # 5 days
TIME_UPDATE_INTERVAL = 30 * 10000

@Timestamp = React.createClass
  displayName: 'Timestamp'

  componentWillMount: ->
    @useRelative = @props.initialUseRelative || Math.abs(Date.now() - Date.parse(@props.time)) < RELATIVE_TIME_WITHIN_THRESHOLD

  componentDidMount: ->
    @interval = setInterval((=> @forceUpdate()), TIME_UPDATE_INTERVAL) if @useRelative

  componentWillUnmount: ->
    clearInterval @interval if @interval

  render: ->
    time = moment(@props.time)

    @transferPropsTo span className: 'timestamp', title: time.format('llll'), (if @useRelative then time.fromNow() else time.format('l'))
