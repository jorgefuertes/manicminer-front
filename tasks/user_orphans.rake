# Seeks orphans

namespace :user do
    desc 'Seek and delete orphans'
    task :orphans => :environment do
        logger.level = 4
        shell.say "> Seeking orphans"
        progressbar = ProgressBar.create(:title => "Workers", :starting_at => 0, :total => Worker.count)
        Worker.find_each do |worker|
            progressbar.increment
            user = User.find(worker.user_id)
            unless user
                shell.say
                shell.say "    - Worker #{worker.id} has no user #{worker.user_id} "
                worker.destroy
                shell.say "DESTROYED"
                shell.say
            end
        end
        progressbar = ProgressBar.create(:title => "Wallets", :starting_at => 0, :total => Wallet.count)
        Wallet.find_each do |wallet|
            progressbar.increment
            user = User.find(wallet.user_id)
            coin = Coin.find(wallet.coin_id)
            unless user
                shell.say "    - Wallet #{wallet.id} has no user #{wallet.user_id} "
                wallet.destroy
                shell.say "DESTROYED"
                shell.say
            end
            unless coin
                shell.say "    - Wallet #{wallet.id} has no coin #{wallet.coin_id} "
                wallet.destroy
                shell.say "DESTROYED"
                shell.say
            end
        end
        progressbar = ProgressBar.create(:title => "Transactions", :starting_at => 0, :total => Transaction.count)
        Transaction.find_each do |transaction|
            progressbar.increment
            user = User.find(transaction.user_id)
            unless user
                shell.say "    - Transaction #{transaction.id} has no user #{transaction.user_id} "
                transaction.destroy
                shell.say "DESTROYED"
                shell.say
            end
        end
        shell.say "Done"
    end # End task
end # End orphans
