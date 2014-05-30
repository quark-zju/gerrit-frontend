{span} = React.DOM

@Username = React.createClass
  displayName: 'Username'

  render: ->
    user = @props.user
    @transferPropsTo span className: 'username', title: user.email, user.name
