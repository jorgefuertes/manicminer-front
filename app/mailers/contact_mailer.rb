ManicminerPool::App.mailer :contact do
	# You may change to valid emails
	support_mail = 'support@yourdomain.com'
	support_mail = 'soporte@yourdomain.com' if I18n.locale.to_s == 'es'
	email :contact_email do |mail|
		from mail[:user].email
		to support_mail
		subject "#{I18n::translate('forms.contact.title')}: #{mail[:subject]}"
		render "contact_email-#{I18n.locale}", :layout => :mail, :locals => {:mail => mail}
		content_type :html
		via :smtp
	end
end
