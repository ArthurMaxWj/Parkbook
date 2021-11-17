require 'twilio-ruby' # Get twilio-ruby from twilio.com/docs/ruby/install

class SendSmsJob < ApplicationJob
  queue_as :default

  def perform(booking, sms)
    return if ENV['ENABLE_SMS'] == 'no'

    # Get your Account Sid and Auth Token from twilio.com/user/account
    account_sid = ENV['TWILIO_ACCOUNT_SID']
    auth_token = ENV['TWILIO_AUTH_TOKEN']
    @client = Twilio::REST::Client.new(account_sid, auth_token)

    message = @client.account.messages.create(
      body: "Your parking place has been booked: \n #{@booking}",
      to: ENV['SMS_FROM'],
      from: sms
    )
  end
end
