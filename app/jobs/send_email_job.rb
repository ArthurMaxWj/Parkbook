class SendEmailJob < ApplicationJob
  queue_as :default

  def perform(booking, email)
    NotifMailer.confirmation(booking, email).deliver
  end
end
