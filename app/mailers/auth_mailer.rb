# auth_mailer.rb

ManicminerPool::App.mailer :auth do
	email :registration_email do |token|
		to token.user.email
		subject I18n::translate('email.welcome')
		locals :token => token
		render "registration_email-#{I18n.locale}", :layout => :mail, :locals => {:token => token}
		content_type :html
		via :smtp
	end

	email :recover_email do |token|
		to token.user.email
		subject I18n::translate('email.recover')
		locals :token => token
		render "recover_email-#{I18n.locale}", :layout => :mail, :locals => {:token => token}
		content_type :html
		via :smtp
	end
end
