Rails.application.routes.draw do
  root 'front#web_console'
  get '/auth/slack/callback', to: 'slack_login#auth_login'
  get '/force-login', to: 'slack_login#force_login'

  get '/slack-api-entry', to: 'slack_single#api_entry_web'
  post '/slack-api-entry', to: 'slack_single#api_entry'

  get '/login', to: 'front#login'
  get '/logout', to: 'slack_login#logout'
  get '/web-console', to: 'front#web_console'
end
