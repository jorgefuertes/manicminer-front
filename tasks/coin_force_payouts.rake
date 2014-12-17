# coin_force_payout.rake

namespace :coin do
    desc 'Force payouts out to users'

    task :force_payouts => :environment do
        logger.level = 4
        include RedisHelpers
        include CoindHelpers
        include ExchangeHelpers
        include UiHelpers
        require 'pp'

        if Padrino.env != :production
            shell.say "\n\n"
            shell.say "Only at production environment!", [:white, :on_red]
            shell.say "Use as: "
            shell.say "padrino -e production coin:force_payouts", :cyan
            shell.say "\n"
            exit
        end

        taskId = 'task-coin-payouts-up'
        dont_remove = true

        at_exit do
            unless dont_remove
                delRedisKey(taskId)
                shell.say "\n> Semaphore removed"
            end
            shell.say "Bye!"
        end

        if getRedisKey(taskId)
            shell.say "> Refushing to start because another instance is running", :yellow
            shell.say "  PID and DATE: "
            shell.say getRedisKey(taskId), :red
            shell.say "  To remove exec: redis-cli del #{taskId}"
            exit
        else
            shell.say "> Semaphore ON"
            setRedisKey(taskId, "#{Process.pid}: #{Time.now}")
            dont_remove = false
        end

        shell.say "COINS:", :yellow
        Coin.find_each do |coin|
            shell.say "#{coin.symbol} ", :cyan
            shell.say "#{coin.name} "
            shell.say("ACTIVE", :green) if coin.active
            shell.say("INACTIVE", :red) unless coin.active
        end

        symbol = shell.ask "Make a FORCED PAYOUT of coin with symbol? "

        coin = Coin.where(:symbol => symbol).first
        unless coin
            shell.error "Coin '#{symbol}' not found!"
            exit
        end

        coinClient = getCoinClient(coin)
        unless coinClient
            shell.error "Cannot connect with coin"
            exit
        end

        shell.say "> Calculating operation costs"

        begin
            rates = getBtcAllRates(coin)
            btcRate = rates[:lowest]
            btcLastRate = rates[:last]
        rescue Exception => e
            shell.error "Cannot get the BTC rates!"
            shell.error e.message
            exit
        end
        if btcRate == 0
            shell.error "Sorry, BTC lowest rate is zero!"
            exit
        end
        shell.say "> 1 "
        shell.say "#{coin.symbol} ", :yellow
        shell.say "= "
        shell.say "#{floatToHuman btcRate} ", :cyan
        shell.say "BTC", :magenta
        walletCount       = coin.wallets.where(:active => true).count
        upperLimitCounter = 0
        counter           = 1
        toPayOut          = 0.0
        payOutCounter     = 0
        btcCost           = 0.0
        btcPayCounter     = 0
        negativeCounter   = 0
        zeroCounter       = 1
        toTrade           = 0.0

        shell.say "> Accounting "
        shell.say "#{walletCount} ", :cyan
        shell.say "wallets"

        coin.wallets.where(:active => true).each do |wallet|
            if counter % 500 == 0
                shell.say "> Accounted "
                shell.say "#{counter} ", :cyan
                shell.say "by now, be patient..."
            end
            begin
                walletBalance = coinClient.getbalance(wallet.user.name)
            rescue
                shell.error "Coind at Host: #{wallet.coin.rpcHost} port: #{wallet.coin.rpcPort} Coin: "\
                    "#{wallet.coin.symbol} not responding!"
                shell.error "Cannot continue without estable connection!"
                exit
            end
            if walletBalance > 50000
                walletBalance = 50000
                upperLimitCount += 1
            end

            if walletBalance > 0
                if coinValidateAddress(wallet)
                    payOutCounter += 1
                    toPayOut += walletBalance
                else
                    btcPayCounter += 1
                    btcCost += (walletBalance * btcRate)
                    toTrade += walletBalance
                end
            elsif walletBalance == 0
                zeroCounter += 1
            else
                negativeCounter +=1
            end

            counter += 1
        end

        totalFunds = coinClient.getbalance()

        shell.say "PAYMENT ESTIMATE", [:white, :on_blue]
        shell.say "> #{payOutCounter} payouts "
        shell.say "#{coin.symbol}: ", :green
        shell.say floatToHuman(toPayOut), :cyan
        shell.say "> #{btcPayCounter} wallets to change as a total "
        shell.say "BTC: ", :green
        shell.say floatToHuman(btcCost), :cyan
        shell.say "> #{upperLimitCounter} wallets have reached the 50000 units limit" if upperLimitCounter > 0
        shell.say "> #{negativeCounter} wallets has a negative balance, not accounted" if negativeCounter > 0
        shell.say "> #{zeroCounter} wallets with zero balance" if zeroCounter > 0
        shell.say "> TO TRADE: ", :green
        shell.say "#{floatToHuman toTrade} ", :cyan
        shell.say "at "
        shell.say "#{floatToHuman btcLastRate} BTC ", :magenta
        shell.say " = "
        shell.say "#{floatToHuman(toTrade * btcLastRate)} BTC", :green
        shell.say "> Total funds available: #{totalFunds} #{coin.symbol}"
        shell.say "> Total to pay: #{floatToHuman(toPayOut + toTrade)} #{coin.symbol}"
        if totalFunds < (toPayOut + toTrade)
            shell.say "> SORRY, ", :red
            shell.say "insufficient funds to pay!"
            exit
        end

        unless shell.yes?("Really do a forced payout of #{symbol}?")
            shell.error "Canceled"
            exit
        end

        ### REAL PAYOUTS ###
        walletCount       = coin.wallets.where(:active => true).count
        upperLimitCounter = 0
        counter           = 1
        toPayOut          = 0.0
        payOutCounter     = 0
        btcCost           = 0.0
        btcPayCounter     = 0
        negativeCounter   = 0
        zeroCounter       = 1
        toTrade           = 0.0
        fees              = 0.0
        bigpaymentHash    = {}

        begin
            btcCoin = Coin.first(:symbol => 'BTC')
            btcCoinClient = getCoinClient(btcCoin)
        rescue Exception => e
            shell.say "Cannot get BTC client!", :red
            shell.error e.message
            exit
        end

        coin.wallets.where(:active => true).each do |wallet|
            if counter % 500 == 0
                shell.say "> Processed "
                shell.say "#{counter} ", :cyan
                shell.say "by now, be patient..."
            end
            begin
                walletBalance = coinClient.getbalance(wallet.user.name)
            rescue
                shell.error "Coind at Host: #{wallet.coin.rpcHost} port: #{wallet.coin.rpcPort} Coin: "\
                    "#{wallet.coin.symbol} not responding!"
                shell.error "Cannot continue without estable connection!"
                exit
            end
            if walletBalance > 50000
                walletBalance = 50000
                upperLimitCount += 1
            end

            begin
                walletBalance = coinClient.getbalance(wallet.user.name)
                walletBalance = 50000 if walletBalance > 50000
            rescue
                shell.error "Coind at Host: #{wallet.coin.rpcHost} port: #{wallet.coin.rpcPort} Coin: "\
                    "#{wallet.coin.symbol} not responding!"
                shell.error "Cannot continue without estable connection!"
                exit
            end

            if walletBalance > 0
                shell.say "#{wallet.user.name}:#{wallet.name} "
                shell.say "--> ", :yellow
                shell.say "#{wallet.address} "
                shell.say "#{walletBalance}#{wallet.coin.symbol} ", :cyan
                shell.say "TXFEE "
                shell.say "FREE ", :red
                if coinValidateAddress(wallet)
                    begin
                        coinClient.move(wallet.user.name, 'bigpayout', walletBalance)
                        bigpaymentHash.store(wallet.address, walletBalance)
                        Transaction.create(:wallet => wallet, :amount => -walletBalance, :comments => 'FORCED PAYOUT')
                        payOutCounter += 1
                        toPayOut += walletBalance
                        shell.say "OK", :green
                    rescue Exception => e
                        shell.say "FAILED", :red
                        shell.say "* Exception! #{e.message}"
                        shell.error "> Unhandled exception!"
                        shell.error "> #{e.message}"
                        exit
                    end

                    restFee = coinClient.getbalance(wallet.user.name)
                    if restFee > 0
                        shell.say "> Sending TxFee from #{wallet.user.name}: #{restFee} #{coin.symbol} "
                        begin
                            coinClient.move(wallet.user.name, 'pooladmin', restFee)
                            Transaction.create(:wallet => wallet, :dtnAddress => 'TXFEE',
                                :amount => -restFee, :fee => 0, :comments => 'FEE')
                            fees += restFee
                            shell.say "OK", :gresen
                        rescue Exception => e
                            shell.say "FAILED", :red
                            shell.say "ERROR TXFEE: ", :red
                            shell.say "#{e.message}"
                            exit
                        end
                    end
                else
                    btcPayCounter += 1
                    btcCost += (walletBalance * btcRate)
                    toTrade += walletBalance
                    shell.say " --> "
                    shell.say "TRADE", :green
                    shell.say "> "
                    shell.say "AUTOTRADE ", :magenta
                    shell.say "#{floatToHuman walletBalance} ", :cyan
                    shell.say " --> "
                    shell.say "#{floatToHuman(walletBalance * btcRate)} BTC ", :magenta
                    begin
                        coinClient.move(wallet.user.name, 'btctrade', walletBallance)
                        Transaction.create(:wallet => wallet, :dtnAddress => 'TO BTCTRADE',
                            :amount => -restFee, :fee => 0, :comments => 'FORCED TRADE')
                        ok = true
                    rescue Exception => e
                        ok = false
                        shell.say "FAILED", :red
                        shell.error e.message
                    end
                    if ok == true
                        btcUserWallet = wallet.user.wallets.first(:coin_id => btcCoin.id)
                        begin
                            btcCoinClient.move('btctrade', wallet.user.name, (walletBalance * btcRate))
                            Transaction.create(:wallet => btcUserWallet, :dtnAddress => 'FROM BTCTRADE',
                                :amount => (walletBalance * btcRate), :fee => 0, :comments => "FORCED #{coin.symbol} AUTOTRADE")
                            shell.say "OK", :green
                        rescue Exception => e
                            shell.say "FAILED", :red
                            shell.error e.message
                            exit
                        end
                    end
                end
            elsif walletBalance == 0
                zeroCounter += 1
            else
                negativeCounter +=1
            end

            counter += 1
        end # Wallet loop

        shell.say "------------- BIG TRANSACTION: -------------", :cyan
        pp bigpaymentHash
        shell.say "--------------------------------------------", :cyan

        coinClient.sendmany('bigpayout', bigpaymentHash)

        shell.say "PAYMENT RESULTS", [:white, :on_blue]
        shell.say "> #{payOutCounter} payouts maded of "
        shell.say "#{coin.symbol}: ", :green
        shell.say floatToHuman(toPayOut), :cyan
        shell.say "> #{btcPayCounter} wallets changed to a total "
        shell.say "BTC: ", :green
        shell.say floatToHuman(btcCost), :cyan
        shell.say "> #{upperLimitCounter} wallets have reached the 50000 units limit" if upperLimitCounter > 0
        shell.say "> #{negativeCounter} wallets has a negative balance, not accounted" if negativeCounter > 0
        shell.say "> #{zeroCounter} wallets with zero balance" if zeroCounter > 0
        shell.say "> TO TRADE: ", :green
        shell.say "#{floatToHuman toTrade} #{coin.symbol}", :cyan
        shell.say "at "
        shell.say "#{floatToHuman btcLastRate} BTC ", :magenta
        shell.say " = "
        shell.say "#{floatToHuman(toTrade * btcLastRate)} BTC", :green
        shell.say "> TRADE REAL NET: ", :green
        shell.say "#{floatToHuman(toTrade * btcLastRate)} - #{floatToHuman btcCost} = "
        shell.say "#{floatToHuman((toTrade * btcLastRate) - btcCost)} BTC", :magenta
        shell.say "FEES EARNED: #{floatToHuman fees} #{coin.symbol}"
        shell.say "> Done."

    end # End task
end # End coin
