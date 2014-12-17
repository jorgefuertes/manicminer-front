# Custom task to make user stats

namespace :stats do
	desc 'Calculate user stats'
	task :users_speed => :environment do
        logger.level = 4
        include UiHelpers
        include StatsHelpers
        include RedisHelpers

		shell.say "> Calculating stats from redis"

        getRedisUsersPercent.each do |key, user|
            idStr      = key.ljust(30, '.')
            userStr    = user[:name][0..19].ljust(20, '.')
            speedStr   = user[:speed].to_f.round(4).to_s.rjust(20, '.')
            percentStr = user[:percent].to_f.round(4).to_s.rjust(20, '.')
            shell.say "  #{idStr}#{userStr}#{speedStr}#{percentStr} %"
        end

	end # End task
end # End stats
