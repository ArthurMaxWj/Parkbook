class SlackLoginController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :auth_login # we switch security off

  def auth_login
    unless session[:already_logged_in]
      session[:already_logged_in] = true

      session[:user_id] = slack_answear.info.user_id
      session[:user_name] = slack_answear.info.names
      puts ">>>#{slack_answear}" # FIXME look here, error, idk why
    end

    load_cur_user
    redirect_to '/web-console'
  end

  # the other stuff doesn't work so...
  def force_login   # TODO delete this -- but later
    session[:already_logged_in] = true

    session[:user_id] = '123'
    session[:user_name] = 'ArturW'
    session[:timezone] = 'Warsaw/Poland'

    load_cur_user
    redirect_to '/web-console'
  end

  def logout
    session[:already_logged_in] = false

    redirect_to '/login'
  end

  private

  def slack_answear
    request.env['omniauth.auth']
  end

  def load_cur_user
    CurrentUser.deinit
    CurrentUser.init(id: session[:user_id], name: session[:user_name], timezone: session[:timezone])
  end
end
