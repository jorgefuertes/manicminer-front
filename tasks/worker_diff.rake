# worker_diff.rake

namespace :worker do
    desc 'Fix workers difficulty between 4 and 5000'
    task :diff => :environment do
        logger.level = 4

        Worker.where(:difficulty.lt => 4).each do |worker|
            shell.say "#{worker.user.name}.#{worker.name}: "
            shell.say "#{worker.difficulty} ", :red
            if worker.difficulty < 4
                shell.say " FIXING TO "
                shell.say "4 ", :cyan
                worker.difficulty = 4
            end

            if worker.save
                shell.say "OK", :green
            else
                shell.say "FAIL", :red
            end
        end

        Worker.where(:difficulty.gt => 5000).each do |worker|
            shell.say "#{worker.user.name}.#{worker.name}: "
            shell.say "#{worker.difficulty} ", :red
            if worker.difficulty > 5000
                shell.say " FIXING TO "
                shell.say "5000 ", :cyan
                worker.difficulty = 5000
            end

            if worker.save
                shell.say "OK", :green
            else
                shell.say "FAIL", :red
            end
        end

        shell.say "Done"
    end # End task
end # End stats

