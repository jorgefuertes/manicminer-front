# user_info.rake

namespace :user do
    desc 'User information'
    task :info => :environment do
        logger.level = 4
        include UiHelpers
        include StatsHelpers
        include RedisHelpers
        include CoindHelpers

        username = shell.ask "Username?"
        user = User.first(:name => username)
        if user
       		shell.say ">   Username: #{user.name}"
       		shell.say "          ID: #{user.id}"
       		shell.say "       email: #{user.email}"
       		shell.say "   Activated: #{user.active ? 'yes' : 'no'}"
       		shell.say "     Seen at: #{user.seen_at}"
       		shell.say "      Locked: #{user.nologin ? 'yes' : 'no'}"
       		shell.say "     Seen at: #{user.seen_at}"
       		shell.say "     Created: #{user.created_at}"
       		shell.say "     Updated: #{user.updated_at}"
       		shell.say "     Workers: #{user.workers.count}"
          user.workers.each do |worker|
            shell.say "              #{worker.name}: "
            if isWorkerRunning worker
              shell.say "#{hashesToHuman(getRedisWorkerSpeed(worker), false)}"
            else
              shell.say "Inactive"
            end
          end
       		shell.say "     Wallets: #{user.wallets.count}"
          user.wallets.each do |wallet|
            shell.say "              #{wallet.name} "
            shell.say "(#{wallet.address}) ", :blue
            shell.say "#{getBalance(wallet)} ", :green
            shell.say "#{wallet.coin.symbol}", :cyan
          end
       		shell.say "Transactions: #{user.transactions.count}"
          shell.say "       Speed: #{hashesToHuman(getRedisUserSpeed(user), false)}"
        else
        	shell.error "Not found!"
        end
        shell.say "> Done."
    end # End task
end # End coin
