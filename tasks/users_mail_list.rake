# users_mail_list.rake

# Extracts a complete username|email list

namespace :users do
    desc 'Complete emails list'
    task :mail_list => :environment do
        logger.level = 4
        shell.say "> All emails:"
        User.where(:active => true, :emailConfirm => true).each do |user|
        	shell.say "#{user.name}|#{user.email}"
        end
        shell.say "> EOF"
    end # End task
end # End orphans
