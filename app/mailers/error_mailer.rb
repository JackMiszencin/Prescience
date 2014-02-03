class ErrorMailer < ActionMailer::Base
	default :to => "jack.miszencin@gmail.com"
	default :from => "presciencemailer@gmail.com"
	def send_error(message)
		@message = message.to_s
		mail(:subject => "Error")
	end
end