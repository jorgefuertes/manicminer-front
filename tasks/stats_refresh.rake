# stats_refresh.rb

namespace :stats do
    desc 'Refresh the stats'
    task :refresh => :environment do
        logger.level = 4
        include StatsHelpers
        include RedisHelpers
        include UiHelpers

        at_exit do
            shell.say "Ok. Bye!"
        end

        shell.say "                  ", :on_green; shell.say "\n"
        shell.say " Refreshing stats ", [:black, :on_green]; shell.say "\n"
        shell.say "                  ", :on_green; shell.say "\n\n"

        while true do
            shell.say "Freshness: ",  [:yellow]
            shell.say(" false", :red) unless getRedisKey('stats-freshness')
            if getRedisKey('stats-freshness')
                old = getRedisKey('stats-freshness').to_i
                shell.say("#{old} ", :green)
                shell.say("#{Time.now.to_i - old} secons ago.", :cyan)
            end

            shell.say "Force refresh... "
            statsRefresh(true)
            shell.say "OK", :green

            shell.say "Graphic stats:"
            # Graphic stats
            # stats-minute-%d%m%Y-%H%M = speed
            # stats-hour-last = %d%m%Y-%H
            this_minute     = Time.now.utc.strftime "%H:%M"
            this_minute_key = "stats-minute-#{this_minute}"
            this_hour       = Time.now.utc.strftime "%H"
            last_speed      = getRedisKey('stats-total-speed')
            # Store minute speed
            minute_stats = {
                :users => activeUsersCount,
                :workers => activeWorkersCount,
                :speed => last_speed
            }
            setRedisKey(this_minute_key, minute_stats.to_json, 24 * 60 * 60)
            shell.say "  This minute speed: #{this_minute_key} -> #{getRedisKey(this_minute_key).to_s}"
            shell.say "  This hour: #{this_hour}UTC -> #{getRedisKey('stats-hour-last')}UTC "
            if this_hour != getRedisKey('stats-hour-last')
                last_hour = getRedisKey('stats-hour-last')
                # New hour
                shell.say "DIFF", :red
                setRedisKey('stats-hour-last', this_hour)
                sum_hour_speed   = 0.0
                sum_hour_users   = 0
                sum_hour_workers = 0
                min_hour_speed   = 9e9
                min_hour_workers = 9e9
                min_hour_users   = 9e9
                max_hour_speed   = 0.0
                max_hour_workers = 0
                max_hour_users   = 0
                (0..59).each do |m|
                    key = "stats-minute-#{last_hour}:#{m}"
                    begin
                        minute_stats = JSON.parse(getRedisKey(key), :symbolize_names => true)
                    rescue
                        minute_stats = {:users => 0, :workers => 0, :speed => 0.0}
                    end
                    sum_hour_speed   += minute_stats[:speed].to_f
                    sum_hour_users   += minute_stats[:users].to_i
                    sum_hour_workers += minute_stats[:workers].to_i
                    max_hour_speed    = minute_stats[:speed].to_f if minute_stats[:speed].to_f > max_hour_speed
                    min_hour_speed    = minute_stats[:speed].to_f if minute_stats[:speed].to_f < min_hour_speed
                    max_hour_workers  = minute_stats[:workers].to_i if minute_stats[:workers].to_i > max_hour_workers
                    min_hour_workers  = minute_stats[:workers].to_i if minute_stats[:workers].to_i < min_hour_workers
                    max_hour_users    = minute_stats[:users].to_i if minute_stats[:users].to_i > max_hour_users
                    min_hour_users    = minute_stats[:users].to_i if minute_stats[:users].to_i < min_hour_users
                end
                avg_hour_speed = sum_hour_speed / 60
                avg_hour_users = sum_hour_users / 60
                avg_hour_workers = sum_hour_workers / 60
                shell.say "    Speed #{last_hour}UTC: "
                shell.say "Avg #{hashesToHuman(avg_hour_speed, false)} "
                shell.say "Min #{hashesToHuman(min_hour_speed, false)} "
                shell.say "Max #{hashesToHuman(max_hour_speed, false)}"
                shell.say "    Average users #{last_hour}UTC: "
                shell.say "Avg #{avg_hour_users} Min #{min_hour_users} Max #{max_hour_users}"
                shell.say "    Average workers #{last_hour}UTC: "
                shell.say "Avg #{avg_hour_workers} Min #{min_hour_workers} Max #{max_hour_workers}"

                shell.say "    Stats hourly reg: "
                if HourlyStats.where(:created_at.gte => Time.now.utc).where(:hour => last_hour).count > 0
                    shell.say "EXISTS", :red
                else
                    statsReg = HourlyStats.create({
                        :hour       => last_hour.to_i,
                        :maxUsers   => max_hour_users,
                        :maxWorkers => max_hour_workers,
                        :maxSpeed   => max_hour_speed,
                        :minUsers   => min_hour_users,
                        :minWorkers => min_hour_workers,
                        :minSpeed   => min_hour_speed,
                        :avgUsers   => avg_hour_users,
                        :avgWorkers => avg_hour_workers,
                        :avgSpeed   => avg_hour_speed
                    })
                    shell.say "#{statsReg.id} ", :blue
                    shell.say "OK", :green
                end
            else
                shell.say "SAME", :green
            end

        	shell.say "Freshness:  ",  [:yellow]
        	shell.say(" false", :red) unless getRedisKey('stats-freshness')
        	shell.say("#{getRedisKey('stats-freshness')}", :green) if getRedisKey('stats-freshness')

            shell.say "Sleeping 30 seconds..."
            sleep 30
        end
    end # End task
end # End namespace
