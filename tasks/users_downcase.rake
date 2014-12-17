# Convert usernames and workers to downcase

namespace :users do
    desc 'Convert usernames and workers to downcase'
    task :downcase => :environment do
        logger.level = 4
        shell.say "+ Converting usernames"
        userCount = 0
        User.find_each do |user|
            newname = user.name.downcase
            if newname != user.name
                shell.say " - #{user.name} --> #{newname} "
                user.name = newname
                if user.save
                    shell.say "OK"
                    userCount += 1
                else
                    shell.say "ERROR ***"
                end
            end
        end
        shell.say "+ Converting worker names"
        workerCount = 0
        Worker.find_each do |worker|
            newname = worker.name.downcase
            if newname != worker.name
                shell.say " - #{worker.name} --> #{newname} "
                worker.name = newname
                if worker.save
                    shell.say "OK"
                    workerCount += 1
                else
                    shell.say "ERROR"
                end
            end
        end

        shell.say "> EOF: #{userCount} users and #{workerCount} workers converted."
    end # End task
end # End namespace
