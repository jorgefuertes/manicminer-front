# Delete a user by id

namespace :user do
    desc 'Delete a user by his ID'
    task :delete => :environment do
        logger.level = 4
        shell.say "> Delete a user by ID"
        id = shell.ask "User ID? "
        shell.say "> Seeking user: #{id}"
        user = User.find(id)
        if user
            shell.say "Deleting workers..."
            user.workers.each do |worker|
                shell.say "  #{worker.name}"
                worker.destroy
            end
            shell.say "Deleting wallets..."
            user.wallets.each do |wallet|
                shell.say "  #{wallet.name}"
                wallet.destroy
            end
            shell.say "Deleting transactions..."
            user.transactions.each do |t|
                shell.say "  #{t.id}"
                t.destroy
            end
            shell.say "Deleting user..."
        	user.destroy
        	shell.say "User deleted!"
        else
        	shell.say "User not found!"
        end
        shell.say "Done"
    end # End task
end # End stats
