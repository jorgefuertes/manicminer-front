# Check payout addresses

namespace :wallet do
    desc 'Check wallets address'
    task :address_check => :environment do
        logger.level = 4
        include RedisHelpers
        include CoindHelpers

        while true do
            counter      = 0
            total        = Wallet.count
            invalidCount = 0
            errorCount   = 0
            shell.say "> Checking "
            shell.say "#{total} ", :cyan
            shell.say "addresses "
            shell.say "BE PATIENT...", :yellow
            Wallet.find_each do |wallet|
                counter += 1
                if counter % 5000 == 0
                    shell.say "> Checked "
                    shell.say "#{counter} ", :cyan
                    shell.say "by now..."
                end
                unless wallet.address =~ /^\*/ or wallet.coin.active == false
                    begin
                        unless coinValidateAddress(wallet)
                            invalidCount += 1
                            shell.say "> #{wallet.user.name}:#{wallet.coin.symbol}:#{wallet.address} is invalid "
                            shell.say "OVERWRITE", :red
                            wallet.address = "*** INVALID ADDRESS: #{wallet.address[0..32]} ***"
                            wallet.save!
                        end
                    rescue Exception => e
                        errorCount += 1
                        counter -= 1
                        shell.say "* Problem validating ", :red
                        shell.say "#{wallet.coin.symbol} ", :cyan
                        shell.say "address! Exception: #{e.message}"
                    end
                end
            end # Wallets loop
            shell.say "= DONE", :green
            shell.say "= Checked.......: #{counter} from #{total}"
            shell.say "= Daemon errors.: #{errorCount}"
            shell.say "= Invalid.......: #{invalidCount}"
            shell.say "> Sleeping 300 seconds"
            sleep 300
        end # Main loop

    end # End task
end # End namespace
