Rails.application.routes.draw do
  %w[get post].each do |verb|
    send verb, '/passwords', controller: 'pages', action: 'passwords'
  end

  get '/:hostname/:change_id', controller: 'changes', action: 'show', as: 'change', constraints: {hostname: /[a-zA-Z0-9]+\.[^\/]*/}
end
