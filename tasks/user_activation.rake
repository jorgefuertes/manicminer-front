# View a token

namespace :user do
    desc 'View token information'
    task :activation => :environment do
        logger.level = 4
        shell.say "> Activate a user"
        username = shell.ask "Username? "
        shell.say "> Seeking user: #{username}"
        user = User.where(:name => username).first
        if user
            user.emailConfirm = true
            user.active = true
            user.save!
            shell.say "User activated!"
        else
        	shell.say "User not found!"
        end
        shell.say "Done"
    end # End task
end # End namespace
