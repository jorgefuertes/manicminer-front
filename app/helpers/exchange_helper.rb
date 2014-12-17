# exchangeHelpers

module ExchangeHelpers
    require 'digest/md5'
    require 'pp'

	def getBtcLastRate(coin)
        rates = getBtcAllRates(coin)
        return rates[:last]
	end

    def getBtcLowestRate(coin)
        rates = getBtcAllRates(coin)
        return rates[:lowest]
    end

    def getBtcAllRates(coin)
        # COMPLETE ... WITH YOUR CREDENTIALS
        # Cryptsy
        cy_pub  = "..."
        cy_pvt  = "..."
        # CryptoRush
        cr_key  = "..."
        cr_id   = "..."
        cr_url  = "https://cryptorush.in/api.php?get=marketv2&m=#{coin.symbol}&b=btc&id=#{cr_id}&key=#{cr_key}"
        # AllCoin
        all_url = "https://www.allcoin.com/api1/pair/#{coin.symbol.downcase}_btc"
        # Bittrex
        bit_url = "https://bittrex.com/api/v1/public/getticker?market=BTC-#{coin.symbol}"

        exchange = 'none'
        error = false

        lastBtc   = 0.0
        lowestBtc = 0.0

        # Cryptsy rates
        begin
            if getRedisKey('cryptsy-markets')
                markets = JSON.parse getRedisKey('cryptsy-markets')
            else
                cryptsyClient = Cryptsy::API::Client.new(cy_pub, cy_pvt)
                markets = cryptsyClient.getmarkets
                setRedisKey('cryptsy-markets', markets.to_json, 120)
            end
        rescue
            error = true
        end

        if markets
            markets['return'].each do |market|
                if market['label'] == "#{coin.symbol}/BTC"
                    lastBtc   = market['last_trade'].to_f
                    lowestBtc = market['low_trade'].to_f
                    exchange  = "cryptsy" if lastBtc > 0 or lowestBtc > 0
                end
            end
        end

        # Allcoin
        if exchange == 'none'
            begin
                uri          = URI.parse(all_url)
                http         = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = true
                request      = Net::HTTP::Get.new(uri.request_uri)
                resp         = http.request(request).body
                parsed       = JSON.parse resp
                lastBtc      = parsed['data']['trade_price'].to_f
                lowestBtc    = parsed['data']['min_24h_price'].to_f
                exchange     = "allcoin" if lastBtc > 0 or lowestBtc > 0
            rescue
                error = true
            end
        end

        # Cryptorush rates
        if exchange == 'none'
            begin
                uri          = URI.parse(cr_url)
                http         = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = true
                request      = Net::HTTP::Get.new(uri.request_uri)
                resp         = http.request(request).body
                parsed       = JSON.parse resp
                lastBtc      = parsed["#{coin.symbol.upcase}/BTC"]['last_trade'].to_f
                lowestBtc    = parsed["#{coin.symbol.upcase}/BTC"]['lowest_24h'].to_f
                exchange     = "cryptorush" if lastBtc > 0 or lowestBtc > 0
            rescue
                error = true
            end
        end

        # Bittrex rates
        if exchange == 'none'
            begin
                uri          = URI.parse(bit_url)
                http         = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = true
                request      = Net::HTTP::Get.new(uri.request_uri)
                resp         = http.request(request).body
                parsed       = JSON.parse resp
                result       = parsed['result']
                lastBtc      = result['Last'].to_f
                lowestBtc    = result['Bid'].to_f
                exchange     = "bittrex" if lastBtc > 0 or lowestBtc > 0
            rescue
                error = true
            end
        end

        if exchange == 'none' and lastBtc == 0 and lowestBtc == 0
            # A shatoshi
            lastBtc   = 0.00000001
            lowestBtc = 0.00000001
            exchange  = 'manicminer'
        end

        return {:error => error, :last => lastBtc.to_f, :lowest => lowestBtc.to_f, :exchange => exchange}
    end

	def getCacheBtcLastRate(coin)
		changesTableJson = getRedisKey('coin-changes-table')
		return 0 unless changesTableJson
		changesTable = JSON.parse(changesTableJson, :symbolize_names => true)
		return 0 if changesTable[:"#{coin.symbol}"].nil?
		return changesTable[:"#{coin.symbol}"][:last_btc_rate].to_f
	end

    def getCacheBtcLowestRate(coin)
        changesTableJson = getRedisKey('coin-changes-table')
        return 0 unless changesTableJson
        changesTable = JSON.parse(changesTableJson, :symbolize_names => true)
        return 0 if changesTable[:"#{coin.symbol}"].nil?
        return changesTable[:"#{coin.symbol}"][:lowest_btc_rate].to_f
    end

    def getCoinTrending(coin)
        if coin.is_a?(Coin)
            symbol = coin.symbol
        else
            symbol = coin
        end
		changesTableJson = getRedisKey('coin-changes-table')
		return '=' unless changesTableJson
		changesTable = JSON.parse(changesTableJson, :symbolize_names => true)
		return '=' if changesTable[:"#{symbol}"].nil?
		return changesTable[:"#{symbol}"][:trend]
    end

    def getCoinTrendingIcon(coin)
        trend = getCoinTrending(coin)
        return "<i class=\"fi-arrow-up zx-green\"></i>" if trend == '+'
        return "<i class=\"fi-arrow-down zx-red\"></i>" if trend == '-'
        return "<i class=\"fi-pause zx-blue\"></i>"
    end

    def getCacheExchange(coin)
        changesTableJson = getRedisKey('coin-changes-table')
        return 'none' unless changesTableJson
        changesTable = JSON.parse(changesTableJson, :symbolize_names => true)
        return 'error' unless changesTable
        return 'nocoin' if changesTable[:"#{coin.symbol}"].nil?
        return 'none' if changesTable[:"#{coin.symbol}"][:exchange].nil?
        return changesTable[:"#{coin.symbol}"][:exchange]
    end

    # A crypted string with operation data
    def crOperation(wallet, funds, btc_rate, btc_total)
        Digest::MD5.hexdigest(%{
            #{wallet.coin.id}
            #{wallet.user.id}
            #{wallet.id}
            #{funds}
            #{btc_rate}
            #{btc_total}
        })
    end

    # Get the user's BTC wallet
    def getUserBtcWallet(user)
        btcCoin = Coin.first(:symbol => 'BTC')
        user.wallets.first(:coin_id => btcCoin.id)
    end

end # module

ManicminerPool::App.helpers ExchangeHelpers
