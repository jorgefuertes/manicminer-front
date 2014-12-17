# Custom task to get last resolved blocks

namespace :coin do
	desc 'Get last resolved blocks'
	task :getlastblocks => :environment do
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

        taskId = 'task-getlastblocks-up'
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
			feeRate = 0.01
			shell.say "Getting last resolved blocks"
			Coin.where(:active => true).each do |coin|
				if coin.getBlocks
					confRequired = coin.confirms
					totalFee = 0
					shell.say "+ "
					shell.say "#{coin.symbol}", :cyan

                    coinClient = getCoinClient(coin)

					lastBlock = coin.blocks.all(:confirmed => true, :sort => :height).last
					if lastBlock
						lastHash = lastBlock.hash
						shell.say "  > Last hash at DB: #{lastHash[1..10]}..."
					else
						lastHash = ""
						shell.say "  > No last hash!"
					end

					begin
						aTransactions = coinClient.listsinceblock lastHash
					rescue
						shell.error "  * Error conecting with #{coin.symbol} daemon!"
					end

					if aTransactions.nil? or aTransactions['transactions'].nil?
						shell.say "  > No new transactions"
					else
						aTransactions['transactions'].each do |transaction|
							if transaction['category'] == 'generate' or transaction['category'] == 'immature'
								newBlock = coinClient.getblock transaction['blockhash']
								totalFee += transaction['amount'] * feeRate

								oldBlock = coin.blocks.first(:hash => transaction['blockhash'])
								if oldBlock
									oldBlock.confirms = transaction['confirmations']
									if (transaction['confirmations'] >= confRequired)
										oldBlock.confirmed = true
										oldBlock.accounted = true if coin.autoShare == false
									end
									if oldBlock.save
										shell.say "  - Updated "
										shell.say "#{coin.symbol} ", :cyan
										shell.say "block #{oldBlock.hash[1..10]}... "\
											"#{transaction['confirmations'].to_s.rjust(4)} "\
											"confirms "
                                        if oldBlock.confirmed
                                            shell.say "CONFIRMED ", :green
                                            shell.say("but accounted", :yellow) if oldBlock.accounted
                                            shell.say("NOT ACCOUNTED", :magenta) unless oldBlock.accounted
                                        else
                                            shell.say "UNCONFIRMED ", :blue
                                            shell.say("but accounted", :yellow) if oldBlock.accounted
                                            shell.say("NOT ACCOUNTED", :magenta) unless oldBlock.accounted
                                        end
									else
										shell.say "  * ERROR updating block!"
									end
								else
									if transaction['confirmations'].nil?
										shell.say "  * Rejecting to update with confirmations NIL"
									else
										shell.say "  + Insert new "
										shell.say "#{coin.symbol} ", :cyan
										shell.say "block: #{transaction['blockhash'][1..10]}... "\
											"#{transaction['confirmations']} confirms "
                                        if coin.autoShare
                                            shell.say "AUTOSHARE", :cyan
                                        else
                                            shell.say "DONT SHARE", :blue
                                        end
                                        accounted = false
                                        accounted = true if coin.autoShare == false
										dbNewBlock = Block.create(
											:coin       => coin,
											:hash       => transaction['blockhash'],
											:height     => newBlock['height'],
											:amount     => transaction['amount'],
											:confirms   => newBlock['confirmations'],
											:difficulty => newBlock['difficulty'],
											:time       => newBlock['time'],
											:accounted  => accounted,
											:confirmed  => false
										)
										shell.say "*** ERROR saving new block ***: "\
											"#{dbNewBlock.errors.full_messages.inspect}" unless dbNewBlock.save
									end
								end
							end
						end # End transactions each
					end

					shell.say "  = #{coin.name} Total Fee = #{totalFee}"
				else
					shell.say "> Coin getBlocks "
					shell.say "deactivated ", :red
					shell.say "for "
					shell.say "#{coin.symbol}", :cyan
				end
			end # Coin-loop

			shell.say "Done", :green
            shell.say "Sleeping 300 seconds..."
            sleep 300
        end

	end # End namespace
end # End task
