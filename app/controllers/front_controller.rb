class FrontController < ApplicationController
  def login
    redirect_to '/web-console' if session[:already_logged_in]
  end

  def web_console
    redirect_to '/login' unless session[:already_logged_in]
    CurrentUser.deinit
    CurrentUser.init(id: session[:user_id], name: session[:user_name])

    @id = CurrentUser.id
    @name = CurrentUser.name

    @command = params[:cmd] || 'help'
  end
end
