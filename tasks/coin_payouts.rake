# Custom task to do autopayouts

namespace :coin do
    desc 'automatic payouts out to users'
    task :payouts => :environment do
        logger.level = 4
        include RedisHelpers
        include CoindHelpers

        if Padrino.env != :production
            shell.say "\n\n"
            shell.say "Only at production environment!", [:white, :on_red]
            shell.say "Use as: "
            shell.say "padrino -e production coin:force_payouts", :cyan
            shell.say "\n"
            exit
        end

        taskId = 'task-payouts-up'
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


        while true do
            Coin.where(:active => true).each do |coin|
                shell.say "> "
                shell.say "#{coin.symbol} ", :cyan
                shell.say "wallets:"
                begin
                    coinClient = getCoinClient(coin)
                    coinBalances = coinClient.listaccounts()
                rescue Exception => e
                    coinBalances = false
                    shell.error "Cannot get accounts for #{coin.symbol}: #{e.message}"
                end
                if coinBalances
                    coin.wallets.where(:active => true).each do |wallet|
                        if wallet.payOn > 0
                            walletBalance = 0
                            restBalance = 0
                            walletBalance = coinBalances[wallet.user.name].to_f if coinBalances[wallet.user.name]
                            if walletBalance > 50000
                                restBalance = walletBalance-50000
                                walletBalance = 50000
                            end
                            if walletBalance > wallet.payOn
                                txFee = wallet.coin.txFee
                                shell.say "#{wallet.user.name}:#{wallet.name} "
                                shell.say "--> ", :yellow
                                shell.say "#{wallet.address} "
                                shell.say "#{walletBalance}#{wallet.coin.symbol} ", :cyan
                                shell.say "PAYON "
                                shell.say "#{wallet.payOn} ", :green
                                shell.say "TXFEE "
                                shell.say "#{txFee} ", :red
                                if walletBalance-txFee > 0
                                    shell.say "GO!", :green
                                    if wallet.address =~ /^\*/
                                        shell.say "> #{wallet.user.name}:#{wallet.coin.symbol}: "
                                        shell.say "#{wallet.address}", :red
                                    else
                                        begin
                                            shell.say " Sending "
                                            shell.say "#{walletBalance-txFee} ", :cyan
                                            coinClient.sendfrom(wallet.user.name,wallet.address,walletBalance-txFee)
                                            Transaction.create(:wallet => wallet, :amount => -walletBalance-txFee,
                                                :comments => 'PAYOUT')
                                            shell.say "OK", :green
                                        rescue Exception => e
                                            shell.say "FAIL", :red
                                            shell.say "* Exception! #{e.message}", :red
                                            if /.*Invalid.*address.*/.match(e.message).nil?
                                                shell.error "> Unhandled exception!"
                                                shell.error "> #{e.message}"
                                            else
                                                shell.say "> #{wallet.user.name}:#{wallet.coin.symbol}:#{wallet.address} is invalid "
                                                shell.say "OVERWRITE", :red
                                                wallet.address = "*** INVALID ADDRESS: #{wallet.address} ***"
                                                wallet.save!
                                            end

                                        end
                                        restFee=coinClient.getbalance(wallet.user.name)
                                        if restFee > 0
                                            shell.say "Rest TXFEE from "
                                            shell.say "#{wallet.user.name} ", :cyan
                                            shell.say "= "
                                            shell.say "#{restFee} ", :red
                                            coinClient.move(wallet.user.name,"pooladmin",restFee)
                                            coinClient.move("pooladmin",wallet.user.name,restBalance) if restBalance > 0
                                            Transaction.create(:wallet => wallet, :dtnAddress => 'TXFEE',
                                                :amount => -txFee, :fee => 0, :comments => 'FEE')
                                            shell.say "OK", :green
                                        end
                                    end
                                else
                                    shell.say "INSUFFICIENT FUNDS", :blue
                                end
                            end
                        end
                    end # Wallet loop
                end # If coinBalances
            end # Coin loop
            shell.say "> Done."
            shell.say "> Sleeping 300 seconds..."
            sleep 300
        end # Loop
    end # End task
end # End namespace
