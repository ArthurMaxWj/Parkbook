require './app/services/user_cli'

class SlackSingleController < ApplicationController
  skip_before_action :verify_authenticity_token # we desable security of forms

  # we enable security of Slack
  before_action :authorize_slack_token if ENV['SLACK_USE_TOKEN_OR_SECRET'] == 'token'
  before_action :authorize_slack_secret if ENV['SLACK_USE_TOKEN_OR_SECRET'] == 'secret'

  before_action :init_curr_user_and_cmd

  # the real entry used by Slack App
  def api_entry
    render html: (UserCli.exec_command(@cmd, display: :txt)).html_safe # OPTIMIZE consider using 'render plain:'
  end

  # a GET request, violates rules for HTTP GET requests,
  # but it's intentional as it allows for additional siple entry form browser
  # (witchout login)
  def api_entry_web
    render html: (UserCli.exec_command(@cmd, display: :web)).html_safe
  end

  private

  def authorize_slack_token # older but simpler
    slack_token = ENV['SLACK_TOKEN']

    render status: 200,
           html: "You are not authorized! Pass token to authorize".html_safe and return if !params.key?(:token)
    render status: 200,
           html: "You are not authorized! Wrong token passed".html_safe and return if params[:token] != slack_token
  end

  def authorize_slack_secret
    slack_secret = ENV['SLACK_SECRET']

    render status: 200,
           html: "You are not authorized! Pass secret to authorize".html_safe and return if request.headers.key?('X-Slack-Signature')
    render status: 200,
           html: "You are not authorized! Wrong secret passed".html_safe and return if (
             request.headers['X-Slack-Signature'] != slack_secret
             )
  end

  def init_curr_user_and_cmd
    puts params
    CurrentUser.deinit
    CurrentUser.init(id: params[:user_id], name: params[:user_name],
                     timezone: Notif.find_by(user_id: params[:user_id])&.timezone)
    @cmd = params.key?(:text) ? params[:text] : 'help'
  end
end
