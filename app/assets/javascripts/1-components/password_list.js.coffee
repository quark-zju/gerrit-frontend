{div, span, table, code, tbody, thead, tr, th, td, i, input, li, ul, p, pre, br, button} = React.DOM

cx = React.addons.classSet

@PasswordList = React.createClass
  displayName: 'PasswordList'

  getInitialState: ->
    passwords: @props.initialPasswords
    busy: false

  handleAddButtonClick: ->
    passwords = @state.passwords
    passwords.push(
      base_url: @state.currentBaseUrl
      username: @state.currentUsername
      password: @state.currentPassword
    )
    @setState {passwords, currentUsername: '', currentBaseUrl: '', currentPassword: ''}

  handleRemoveButtonClick: (baseUrl) ->
    passwords = _.reject(@state.passwords, (x) -> x.base_url == baseUrl)
    @setState {passwords}

  handleSubmitClick: ->
    return if @state.busy
    @setState busy: true
    $.post(
      Routes.passwords_path(),
      passwords: @state.passwords
    ).fail(
      -> alert('Cannot save passwords. Please try again later.')
    ).always(
      => @setState busy: false
    )

  render: ->
    state = @state
    illegalBaseUrl = !state.currentBaseUrl || !state.currentBaseUrl.match(/^https?:\/\/[^.]+\.[^.]+/i) || _.find(state.passwords, (x) -> x.base_url == state.currentBaseUrl)
    div className: 'passwordList',
      table className: 'passwordTable',
        thead null,
          th null, 'Base URL'
          th null, 'Username'
          th null, 'Password'
          th null
        tbody null,
          state.passwords.map (x, y) =>
            tr key: y, className: 'passwordItem',
              td className: 'baseUrl', x.base_url
              td className: 'username', x.username
              td className: 'password', '<hidden>'
              td className: 'actions',
                button className: 'removeButton', onClick: @handleRemoveButtonClick.bind(this, x.base_url), '-'
          tr key: 'new', className: 'passwordItem',
            td className: 'baseUrl',
              input className: cx(illegal: illegalBaseUrl),  name: 'base_url', placeholder: 'https://gerrit.example.com', value: state.currentBaseUrl, onChange: ((e) => @setState currentBaseUrl: e.target.value)
            td className: 'username',
              input name: 'username', placeholder: 'alice', value: state.currentUsername, onChange: ((e) => @setState currentUsername: e.target.value)
            td className: 'password',
              input name: 'password', value: state.currentPassword, onChange: ((e) => @setState currentPassword: e.target.value)
            td className: 'actions',
              button className: 'addButton', disabled: illegalBaseUrl, onClick: @handleAddButtonClick, '+'
      button className: 'submit', disabled: @state.busy, onClick: @handleSubmitClick, 'Update'