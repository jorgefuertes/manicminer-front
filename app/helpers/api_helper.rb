# api_helper.rb

ManicminerPool::App.helpers do
	def to_boolean(s)
  		s and !!s.match(/^(true|t|yes|y|1)$/i)
	end
end
