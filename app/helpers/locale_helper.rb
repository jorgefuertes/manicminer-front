# Locale helper:

ManicminerPool::App.helpers do
	def getLocaleList
		return ['en', 'es']
	end

	def getSubdomainLocale
		subLocale = request.host.split('.')[0]
		return subLocale if getLocaleList.include? subLocale
		return false
	end

	def getBrowserLocale
		browserLocale = "nolocale"
		if request.env['HTTP_ACCEPT_LANGUAGE'].nil? == false
			browserLocale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
		end

		return browserLocale if getLocaleList.include? browserLocale
		return false
	end

	def setLocale
		I18n.locale = getBrowserLocale if getBrowserLocale
		I18n.locale = getSubdomainLocale if getSubdomainLocale
	end

end
