class NotifMailer < ApplicationMailer
    def confirmation(booking, email)
        mail(to: email, subject: 'Parking Rservation')
    end
  end
  