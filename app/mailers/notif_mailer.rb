class NotifMailer < ApplicationMailer
  def confirmation(booking, email)
    @booking = booking

    mail(to: email, subject: 'Parking Rservation')
  end
end
  