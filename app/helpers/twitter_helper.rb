module TwitterHelpers

	def getTwitterClient
		Twitter::REST::Client.new do |config|
			# Complete it with twitter credentials
			config.consumer_key        = "..."
	  		config.consumer_secret     = "..."
  			config.access_token        = "..."
  			config.access_token_secret = "..."
		end
	end

	def getLastTweets
		begin
	  		client = getTwitterClient
	  		return client.user_timeline('ManicMinerPool')[0..10]
	  	rescue Exception => e
	  		logger.debug "ERROR recovering tweets: #{e.message}"
	  		return []
	  	end
	end

	def sendTweet(text)
		client = getTwitterClient
		client.update(text) unless Padrino.env == :development
	end

end

ManicminerPool::App.helpers TwitterHelpers
