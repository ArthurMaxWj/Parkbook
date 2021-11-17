class Notif < ApplicationRecord
  validates :user_id, presence: true

  DEFAULT_TIMEZONE = "Europe/Warsaw"

  def send_notifs(booking)
    SendEmailJob.perform_later(booking, email) if email.nil?
    SendEmailJob.perform_later(booking, sms) if sms.nil?
  end

  def zone
    timezone || DEFAULT_TIMEZONE
  end
end
