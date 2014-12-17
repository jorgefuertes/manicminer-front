# error_mailer.rb

ManicminerPool::App.mailer :error do
	email :error_email do |report|
        # Change to a valid admin email
		to 'admin@yourdomain.com'
		subject 'Error report'
		locals :report => report
		render "error_email", :layout => :mail, :locals => {:report => report}
		content_type :html
		via :smtp
	end
end
