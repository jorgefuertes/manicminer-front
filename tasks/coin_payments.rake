# coin_redis_payments

namespace :coin do
    desc 'Pay users per share'
    task :payments => :environment do
        logger.level = 4
        include UiHelpers
        include StatsHelpers
        include TwitterHelpers
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

        taskId = 'task-payments-up'
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
            # Pool's block fee
            fee = 0.02
            poolAdmin = "pooladmin"

            shell.say "> Getting complete stats..."
            users = getRedisUsersPercent
            shell.say "  + Pool speed: #{users['nouser-total'][:speed]} Khs"
            shell.say "  + Combined: #{users['nouser-combined'][:speed]} Khs"
            while users['nouser-combined'][:percent].to_f.round(8) > 100 do
                shell.say "  > Combined is "
                shell.say "more ", :red
                shell.say "than 100%. Retry in 5 seconds."
                sleep 5
                users = getRedisUsersPercent
                shell.say "  + Combined: #{users['nouser-combined'][:percent].to_f.round(8)} %"
            end
            shell.say
            shell.say "> Calculating and making payments for "\
                "#{Block.where(:accounted => false, :confirmed => true).count} blocks:"

            blocksPayed = 0
            Block.where(:accounted => false, :confirmed => true).each do |block|
                amount = block.amount - (block.amount * fee)
                shell.say "  + Block: #{block.hash[1..10]} #{block.amount} - #{fee} = #{amount}"

                if block.coin.autoShare
                    coinClient = getCoinClient(block.coin)
    
                    # Pay fee to pool
                    coin = block.coin
                    begin
                        coinClient.move('', poolAdmin, block.amount.to_f * fee.to_f)
                        shell.say "  - Fee payed to #{poolAdmin}: #{block.amount.to_f * fee.to_f}"
                    rescue
                        shell.error "  * (fee) - Cannot execute move on #{coin.symbol} daemon!"
                    end
    
                    shell.say "  > Paying lusers:"
                    totalPayed = 0
    
                    users.each do |key, data|
                        shell.say "    > Luser: "
                        shell.say "#{key} "
                        user = User.first(:id => key)
                        if user
                            shell.say "#{user.name}", :magenta
                            wallet = user.wallets.first(:active => true, :coin_id => coin.id)
                            if wallet and data[:percent] > 0
                                payment = data[:percent] * amount.to_f / 100
                                payed = false
                                if coin.integerOnly
                                    shell.say "      - #{coin.symbol}: Payment rounded from #{payment} to #{payment.round}"
                                    payment = payment.round
                                end
                                if payment > 0
                                    begin
                                        coinClient.move('', user.name, payment.to_f)
                                        payed = true
                                    rescue
                                        shell.error "      * (payment) Cannot execute move on #{coin.symbol} daemon!"
                                    end
                                    if payed
                                        totalPayed += payment
                                        shell.say "      - "
                                        shell.say "#{user.name} ", :magenta
                                        shell.say "payed "
                                        shell.say "#{payment} ", :yellow
                                        shell.say "#{coin.symbol}", :cyan
                                        Transaction.create(:wallet => wallet, :dtnAddress => "FROM-BLOCK #{block.id}",
                                            :amount => payment, :fee => 0, :comments => 'MINED')
                                    end
                                else
                                    shell.say "      * Refushed to pay zero."
                                end
                            else
                                shell.say "      - No wallet."
                            end
                        else
                            shell.say "not found!"
                        end # if user user
                    end # users loop
                    
                    block.accounted = true
                    blocksPayed += 1
                    if block.save
                        shell.say "  + Block accounted OK, TOTAL payed #{totalPayed} #{coin.symbol} from #{amount}"
                        totalBlocks = Block.where(:accounted => true).count
                        if (amount - totalPayed) > 0
                            shell.say "  - paying #{poolAdmin} #{amount - totalPayed} #{coin.symbol}"
                            coinClient.move('', poolAdmin, amount - totalPayed)
                            shell.say "  - #{poolAdmin} has been payed #{amount - totalPayed} #{coin.symbol}"
                        else
                            shell.say "  - Rest is zero."
                        end
                        #sendTweet "New #{coin.name} block breaked! Dealing out #{noFloatZero(amount.round(2))}#{coin.symbol} "\
                        #    "to pool users! We have breaked #{totalBlocks} blocks by now." unless coin.symbol == 'ORG'
                    else
                        shell.say "  * Error saving block!"
                    end
                else # Non autoshare
                    shell.say "  > This coin has "
                    shell.say "AUTOSHARE OFF "
                    block.accounted = true
                    block.save
                    shell.say "MARKED AS ACCOUNTED", :yellow
                end # ifAutosahre
            end # Blocks loop
            shell.say "> Done, #{blocksPayed} blocks accounted."
            shell.say "> Sleeping 300 seconds..."
            sleep 300
        end # Loop
    end # End task
end # End coin_payments
