# Only one wallet per coin

namespace :wallet do
    desc 'Check dupes and creates wallets for new coins'
    task :check => :environment do
        logger.level = 4
        include RedisHelpers
        include CoindHelpers

        shell.say "> Seeking for invalid and duped wallets"
        total = User.count
        counter = 0
        User.find_each do |user|
            counter += 1
            if counter % 100 == 0
                shell.say "> Checked "
                shell.say "#{counter}/#{total} ", :cyan
                shell.say " be patient..."
            end
            Coin.find_each do |coin|
                dupes = user.wallets.all(:coin_id => coin.id).count
                if dupes > 1
                    shell.say " > #{user.name}: #{coin.symbol} #{dupes} dupes"
                    duped = user.wallets.last(:coin_id => coin.id)
                    shell.say " - "
                    shell.say "DELETING ", :red
                    shell.say "the second: #{duped.id}"
                   duped.delete!
                end
            end #coin

            user.wallets.all(:active => false).each do |wallet|
                shell.say " > #{user.name}'s wallet #{wallet.name} unactive, "
                shell.say "deleting: ", :red
                if wallet.delete
                    shell.say "OK", :green
                else
                    shell.say "FAIL", :red
                end
            end #unactives

            # Create other wallets
            Coin.where(:active => true).each do |coin|
                wallet = user.wallets.first(:coin_id => coin.id)
                unless wallet
                    shell.say " > #{user.name} creating wallet for #{coin.symbol}: "
                    if Wallet.create(
                            :coin => coin,
                            :user => user,
                            :name => "#{coin.symbol} wallet",
                            :active => true,
                            :address => '*** NO PAYOUT ADDRESS ***',
                        )
                        shell.say "OK", :green
                    else
                        shell.say "FAIL", :red
                    end
                end
            end # loop

        end #user

        shell.say "DONE", :green

    end # End task
end # End namespace
