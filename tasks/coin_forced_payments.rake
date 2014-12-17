# Custom task to do autopayments

namespace :coin do
    desc 'Forced payment to users'
    task :forced_payments => :environment do
        logger.level = 4
        include RedisHelpers
        include CoindHelpers
        include StatsHelpers

        if Padrino.env != :production and Padrino.env != :development
            shell.say "\n\n"
            shell.say "Unknown environment!", [:white, :on_red]
            shell.say "Use as: "
            shell.say "padrino -e production coin:force_payment", :cyan
            shell.say "\n"
            exit
        end

        taskId = 'task-forced-payments-up'
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

        # --- BEGIN ---

        shell.say " *** FORCED PAYMENT *** ", :on_green
        shell.say " HAZARDOUS WARNING", :red
        shell.say

        shell.say "> Moving p2pool balances:"
        Coin.where(:active => true).each do |coin|
            coinClient = Bitcoin::Client.new(coin.rpcUser, coin.rpcPass, :host => coin.rpcHost)
            begin
               coinClient.port = coin.rpcPort
               p2poolBalance = coinClient.getbalance('p2pool')
            rescue Exception => e
               shell.say "ERROR #{coin.symbol} ", :red
               shell.error e.message
               p2poolBalance = 0
	    end

            if p2poolBalance > 0
                shell.say "  + ", :green
                shell.say "#{p2poolBalance} #{coin.symbol} ", :cyan
                begin
                    coinClient.move('p2pool', '', p2poolBalance.to_f)
                    shell.say "OK", :green
                rescue Exception => e
                    shell.say "ERROR", :red
                    shell.error e.message
                    exit
                end
            end
        end

        shell.say "COINS:", :yellow
        Coin.where(:active => true).each do |coin|
            shell.say "#{coin.symbol.ljust(5)} ", :cyan
            shell.say "#{coin.name.ljust(20)} "
            shell.say("  ACTIVE ", :green) if coin.active
            shell.say("INACTIVE ", :red) unless coin.active
            shell.say "#{getOrphanBalance(coin)}", :yellow
        end

        symbol = shell.ask "\nCoin symbol? "

        coin = Coin.where(:symbol => symbol.upcase).first
        unless coin
            shell.error "Coin '#{symbol.upcase}' not found!"
            exit
        end

        orphanBalance = getOrphanBalance(coin)
        shell.say "> Orphan balance for "
        shell.say "#{coin.symbol} ", :cyan
        shell.say "is "
        shell.say orphanBalance, :green

        exit if orphanBalance == "offline"
        exit if orphanBalance == 0

        payAmount = shell.ask "Amount to pay? (Defaults to #{orphanBalance})"
        payAmount = orphanBalance unless payAmount.to_f > 0

        unless shell.yes?("Really do a forced shared payment of #{payAmount} #{symbol}?")
            shell.error "Canceled"
            exit
        end

        # Pool's block fee
        fee = 0.02
        poolAdmin = "pooladmin"

        shell.say "> Getting complete stats..."
        users = getRedisUsersPercent
        shell.say "  + Pool speed: #{users['nouser-total'][:speed]} Khs #{users['nouser-total'][:percent]}%"
        shell.say "  + Combined: #{users['nouser-combined'][:speed]} Khs #{users['nouser-total'][:percent]}%"
        while users['nouser-combined'][:percent].to_f.round(8) > 100 do
            shell.say "Combined is more than 100%. Retry in 5 seconds."
            sleep 5
            users = getRedisUsersPercent
            shell.say "  + Combined: #{users['nouser-combined'][:percent].to_f.round(8)} %"
        end

        shell.say
        shell.say "> Calculating and making forced payments for "
        shell.say "#{payAmount} #{coin.symbol}", :cyan

        paymentFee = payAmount.to_f * fee.to_f
        shell.say "> Pool fee #{fee}% = #{paymentFee}"
        amount = payAmount.to_f - paymentFee.to_f
        shell.say "> Sharing #{amount}"

        coinClient = Bitcoin::Client.new(coin.rpcUser, coin.rpcPass, :host => coin.rpcHost)
        coinClient.port = coin.rpcPort

        # Pay fee to pool
        begin
            coinClient.move('', poolAdmin, paymentFee)
            shell.say "- ", :red
            shell.say "Fee payed to #{poolAdmin}: #{paymentFee}"
        rescue Exception => e
            shell.error "  * (fee) - Cannot execute move on #{coin.symbol} daemon!"
            shell.error e.message
            exit
        end

        shell.say "  > Paying users:"
        totalPayed = 0

        users.each do |key, data|
            shell.say "    > user "
            user = User.first(:id => key)
            if user
                shell.say "#{user.name[0..19].ljust(20)} ", :yellow
                shell.say "#{data[:percent].round(3).to_s.rjust(6)}% "
                wallet = user.wallets.first(:active => true, :coin_id => coin.id)
                if wallet and data[:percent] > 0
                    payment = data[:percent] * amount.to_f / 100
                    payed = false
                    if coin.integerOnly
                        shell.say "INTONLY ", :red
                        shell.say "rounded from #{payment} to #{payment.round} "
                        payment = payment.round
                    end
                    if payment > 0
                        begin
                            coinClient.move('', user.name, payment.to_f)
                            payed = true
                        rescue
                            shell.say "ERROR", :red
                            shell.error "      * (payment) Cannot execute move on #{coin.symbol} daemon!"
                        end
                        if payed
                            totalPayed += payment
                            shell.say "OK ", :green
                            shell.say "payed "
                            shell.say "#{payment} #{coin.symbol}", :cyan
                            Transaction.create(:wallet => wallet, :dtnAddress => "FROM-POOL-ADMIN",
                                :amount => payment, :fee => 0, :comments => 'EXTRA BOUNTY')
                        end
                    else
                        shell.say "Refushed to pay zero", :red
                    end
                else
                    shell.say "No wallet", :red
                end
            else
                shell.say "#{key} not found!", :red
            end
        end # users loop

        shell.say
        shell.say "+ Payment accounted OK, TOTAL payed "
        shell.say "#{totalPayed} #{coin.symbol} ", :cyan
        shell.say "from "
        shell.say "#{amount}", :green

    end # End task
end # End coin
