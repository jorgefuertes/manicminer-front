# Seek for duped usernames

namespace :users do
    desc 'Seek for duplicated usernames'
    task :dupes => :environment do
        logger.level = 4
        shell.say "+ Check usernames"
        userCount = 0
        User.find_each do |user|
        	duped = User.where(:name => user.name, :id.ne => user.id).first
        	if duped
        		shell.say " - DUPED: #{user.name} #{user.id} --> #{duped.id}"
        		userCount += 1
        	end
        end

        shell.say "> EOF: #{userCount} dupes."
    end # End task
end # End namespace
