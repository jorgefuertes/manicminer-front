# Coind helpers

module CoindHelpers
	def getCoinClient(coin)
		coind = Bitcoin::Client.new(coin.rpcUser, coin.rpcPass, :host => coin.rpcHost)
		coind.port = coin.rpcPort
		return coind
	end

	def getBtcCoinClient
		coin = Coin.first(:symbol => 'BTC')
		return getCoinClient(coin)
	end

	def getBalance(wallet)
		return getWalletBalance(wallet)
	end

	def getWalletBalance(wallet)
		return 'unactive' if wallet.active == false
        return rand(50000).to_f if Padrino.env == :development

		begin
			coinClient = getCoinClient(wallet.coin)
		    Timeout::timeout(5) {
    			return coinClient.getbalance(wallet.user.name)
            }
		rescue
			return 'offline'
		end
	end

	def getOrphanBalance(coin)
        return rand(50000).to_f if Padrino.env == :development

		begin
			coinClient = getCoinClient(coin)
		    Timeout::timeout(5) {
    			return coinClient.getbalance("")
            }
		rescue
			return 'offline'
		end
	end

	def getTotalBalance(coin)
        return rand(50000).to_f if Padrino.env == :development

		begin
			coinClient = getCoinClient(coin)
		    Timeout::timeout(5) {
    			return coinClient.getbalance()
            }
		rescue
			return 'offline'
		end
	end

	def getBtcTradeBalance(coin)
        return rand(50000).to_f if Padrino.env == :development

		begin
			coinClient = getCoinClient(coin)
		    Timeout::timeout(5) {
    			return coinClient.getbalance('btctrade')
            }
		rescue
			return 'offline'
		end
	end

	def getPoolAdminBalance(coin)
        return rand(50000).to_f if Padrino.env == :development

		begin
			coinClient = getCoinClient(coin)
		    Timeout::timeout(5) {
    			return coinClient.getbalance('pooladmin')
            }
		rescue
			return 'offline'
		end
	end

	def getDifficulty(coin)
		return 1000 if Padrino.env == :development
		begin
			coind = getCoinClient(coin)
		    Timeout::timeout(5) {
    			return coind.getdifficulty()
            }
		rescue
			return 10000
		end
	end

	def getBlockValue(coin)
	    return coin.blockValue
	end

	def getReward(coin,speed)
           reward = ((speed/1000)*getBlockValue(coin)/getDifficulty(coin)) * 20.11626
	end

	def coinValidateAddress(wallet)
		return true if Padrino.env == :development
		key = "address-#{wallet.address}-valid"
		return true if getRedisKey(key)
		coinClient = getCoinClient(wallet.coin)
		verification = coinClient.validateaddress(wallet.address)
		if verification['isvalid']
		    setRedisKey(key, 1)
    		return true
        else
            return false
        end
	end

	def checkAndCreateWallets(user)
        Coin.where(:active => true).each do |coin|
            wallet = user.wallets.first(:coin_id => coin.id)
            unless wallet
	        	Wallet.create(
	        		:coin => coin,
	        		:user => user,
	        		:name => "#{coin.symbol} wallet",
	        		:active => true,
	        		:address => '*** NO PAYOUT ADDRESS ***',
	        	)
	        end
        end # loop
	end
end

ManicminerPool::App.helpers CoindHelpers
