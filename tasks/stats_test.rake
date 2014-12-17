# stats_test.rb

namespace :stats do
    desc 'Tests new stats system'
    task :test => :environment do
        logger.level = 4
        include UiHelpers
        include StatsHelpers
        include RedisHelpers

        shell.say "               ", :on_green; shell.say "\n"
        shell.say " Testing stats ", [:black, :on_green]; shell.say "\n"
        shell.say "               ", :on_green; shell.say "\n\n"

        statsRefresh

    	shell.say " Freshness: ",  [:black, :on_yellow]
    	shell.say(" false", :red) unless getRedisKey('stats-freshness')
    	shell.say("#{getRedisKey('stats-freshness')}", :green) if getRedisKey('stats-freshness')

    	# ALL THE STATS
    	#stats = JSON.parse getRedisKey('last-stats')
    	#stats.each do |key, value|
    	#	shell.say "  + #{key}: "
    	#	shell.say value.inspect
    	#	shell.say "\n"
    	#end

    	# ONE BY ONE
   		shell.say " Coins:", [:black, :on_yellow]
    	Coin.where(:active => true, :mainChain => true).each do |coin|
    		shell.say "   #{coin.symbol}: ", :cyan
    		shell.say("UP", :green) if getRedisKey("coin-#{coin.id}-up") == 'true'
    		shell.say("DOWN", :red) if getRedisKey("coin-#{coin.id}-up") == 'false'
    		shell.say("UNKNOWN", :blue) if getRedisKey("coin-#{coin.id}-up").nil?
    	end

   		shell.say " Users:", [:black, :on_yellow]
    	User.where(:active => true).each do |user|
    		if getRedisKey("user-#{user.name}-up") == 'true'
    			shell.say "  #{user.name}: ", :magenta
    			shell.say hashesToHuman(getRedisKey("user-#{user.name}-speed").to_f, false)
    			user.workers.each do |worker|
    				name = "#{user.name}.#{worker.name}"
    				if getRedisKey("worker-#{name}-up") == 'true'
    					speed = hashesToHuman(getRedisKey("worker-#{name}-speed").to_f, false)
    					dead  = hashesToHuman(getRedisKey("worker-#{name}-dead-speed").to_f, false)
    				else
    					speed = 0
    					dead  = 0
    				end
					shell.say "    #{worker.name} ", :cyan
					shell.say "#{speed} ", :green
					shell.say "/ "
					shell.say "#{dead}", :red
    			end
    		end
    	end

    	shell.say " TOTAL: ",  [:black, :on_yellow]
    	speed = hashesToHuman(getRedisKey('stats-total-speed').to_f, false)
    	dead  = hashesToHuman(getRedisKey('stats-total-dead-speed').to_f, false)
    	shell.say "#{speed} ", :green
    	shell.say " / "
    	shell.say "#{dead}", :red

        shell.say "\nDone\n"
    end # End task
end # End orphans
