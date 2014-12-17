# Check and alarm

namespace :monitor do
    desc 'Check several things'
    task :check => :environment do
        logger.level = 4
        include RedisHelpers
        include CoindHelpers
        include JabberHelpers
        include UiHelpers
        include StatsHelpers
        require 'net/telnet'

        # Daemons status
    	shell.say "DAEMONS STATUS", [:white, :on_blue]
        Coin.where(:active => true).each do |coin|
       		shell.say "  #{coin.symbol.ljust(5)} ", :cyan
       		key = "#{coin.symbol}-daemon-status"
            retries = 1
            start = Time.now.to_i
            while true do
        		client = getCoinClient(coin)
        		begin
                    Timeout::timeout(15) {
            			client.getbalance('pooladmin')
                    }
        			status = true
        			shell.say "OK ", :green
        			response_time = Time.now.to_i - start
                    color = :blue
        			color = :yellow if response_time > 1
        			color = :red if response_time > 2
                    shell.say "#{response_time} seconds", color
        		rescue
        			status = false
        			shell.say "FAIL ", :red
        		end
        		break if status == true or retries > 4
        		retries += 1
        		shell.say "retrying ", :yellow
            end
            shell.say("!!!", :red) unless status
    		if getRedisKey(key)
                if status and getRedisKey(key) == 'false'
                    sendJabberAlarm "RECOVER: #{coin.name} (#{coin.symbol}) is UP now"
                end
    			if status == false and getRedisKey(key) == 'true'
        			sendJabberAlarm "PROBLEM: #{coin.name} (#{coin.symbol}) is DOWN! (5 retries of 15 seconds)"
                end
    		end
    		setRedisKey(key, status)
    	end #coin

    	shell.say "SPEED STATUS", [:white, :on_blue]
        keyLast     = 'pool-speed-last'
        keyDeadLast = 'pool-speed-dead-last'
        last        = getRedisKey(keyLast)
        last        = last.to_f
        deadLast    = getRedisKey(keyDeadLast)
        deadLast    = deadLast.to_f
        actual      = getPoolSpeed()
        deadActual  = getPoolDeadSpeed()

        percentOk   = ((last / actual) * 100).round(3)
        percentNook = ((deadLast / deadActual) * 100).round(3)

        shell.say "OK:   LAST #{hashesToHuman last, false} NOW #{hashesToHuman actual, false} "\
            "PERCENT #{floatToHuman percentOk}%"
        shell.say "NOOK: LAST #{hashesToHuman deadLast, false} NOW: #{hashesToHuman deadActual, false} "\
            "PERCENT #{floatToHuman percentNook}%"

        if 100 - percentOk > 50
            shell.say "OK SPEED GROWS ", :green
            shell.say "#{100 - percentOk}%. Last: #{hashesToHuman last, false} Actual: #{hashesToHuman actual, false}"
            sendJabberAlarm(
                "OK SPEED GROWS #{100 - percentOk}%\n"\
                "- Last: #{hashesToHuman last, false}\n"\
                "- Actual: #{hashesToHuman actual, false}"
            )
            setRedisKey(keyLast, actual)
        elsif 100 - percentOk < -50
            shell.say "OK SPEED ", :green
            shell.say "REDUCTION ", :red
            shell.say "#{+(100 - percentOk)}%. Last: #{hashesToHuman last, false} Actual: "\
                "#{hashesToHuman actual, false}"
            sendJabberAlarm(
                "OK SPEED REDUCTION #{+(100 - percentOk)}%\n"\
                "- Last: #{hashesToHuman last, false}\n"\
                "- Actual: #{hashesToHuman actual, false}"
            )
            setRedisKey(keyLast, actual)
        end

        if actual < last and actual < 5000
            shell.say "SPEED PROBLEM, VERY LOW ", :red
            shell.say "#{100 - percentOk}%. Last: #{hashesToHuman last, false} Actual: #{hashesToHuman actual, false}"
            sendJabberAlarm(
                "SPEED PROBLEM, WE ARE VERY LOW!\n"\
                "- Actual: #{hashesToHuman actual, false}"
            )
        end

        if 100 - percentNook > 50
            shell.say "NOOK SPEED ", :blue
            shell.say "GROWS ", :red
            shell.say "#{100 - percentNook}%. Last: #{hashesToHuman deadLast, false} Actual: "\
                "#{hashesToHuman deadActual, false}"
            sendJabberAlarm(
                "NOOK SPEED GROWS #{100 - percentNook}%\n"\
                "- Last: #{hashesToHuman deadLast, false}\n"\
                "- Actual: #{hashesToHuman deadActual, false}"
            )
            setRedisKey(keyDeadLast, deadActual)
        elsif 100 - percentNook < -50
            shell.say "NOOK SPEED REDUCTION ", :blue
            shell.say "#{+(100 - percentNook)}%. Last: #{hashesToHuman deadLast, false} "\
                "Actual: #{hashesToHuman deadActual, false}"
            setRedisKey(keyDeadLast, deadActual)
        end

        # HA Proxy
    	shell.say "CHECKING HAPROXY", [:white, :on_blue]
    	shell.say "> Conecting to haproxy: "
    	lastHaStatus = getRedisKey('last-ha-status')
    	lastHaStatus = 'false' if lastHaStatus.nil?
        ha = Net::Telnet::new(
            "Host"       => 'pool.manicminer.in',
            "Port"       => 3333,
            "Timeout"    => 5
        )
        if ha
            shell.say "OK", :green
            sendJabberAlarm('HAPROXY RECOVER: Connect OK') if lastHaStatus == 'false'
            setRedisKey('last-ha-status', 'true')
        else
            shell.say "FAILED", :red
            sendJabberAlarm('HAPROXY: Cannot connect to haproxy!') if lastHaStatus == 'true'
            setRedisKey('last-ha-status', 'false')
        end

        # Services
        service_list = [
            'coin:update_changes',
            'coin:get_profitability',
            'system:backup',
            'wallet:address_check',
            'coin:payments',
            'coin:payouts',
            'stats:refresh',
            'coin:getlastblocks'
        ]

    	shell.say "CHECKING VITAL SERVICES", [:white, :on_blue]
        process_list = %x{ps aux|grep rake}
        service_list.each do |service|
            key = "last-#{service}-status"
            last_service_status = getRedisKey(key)
            last_service_status = 'false' if last_service_status.nil?
            shell.say "  #{service} "
            if process_list.include? service
                shell.say "OK", :green
                sendJabberAlarm("SERVICE RECOVER: #{service}") if last_service_status == 'false'
                setRedisKey(key, 'true')
            else
                shell.say "FALSE", :red
                sendJabberAlarm("SERVICE DOWN: #{service} !!!") if last_service_status == 'true'
                setRedisKey(key, 'false')
            end
        end

        # Service Logs
    	shell.say "CHECKING SERVICE LOGS", [:white, :on_blue]
        Dir['/etc/service/*'].each do |svc|
            shell.say "  #{svc.ljust(40, '.')} "
            if svc.include? "clean-errors"
		        shell.say "PASSED", :yellow
                next
            end
            key = "last-#{svc}-log-status"
            last_service_status = getRedisKey(key)
            last_service_status = 'false' if last_service_status.nil?
            begin
                last_tai  = Tai64.parse(%x{tail -n1 #{svc}/log/main/current})
                limit = Time.now - 2.hour
                if last_tai.tai_second < limit.to_i
                    shell.say "OLD", :red
                	sendJabberAlarm("SERVICE LOG TOO OLD: #{svc} !!!") if last_service_status == 'true'
	                setRedisKey(key, 'false')
                else
                    shell.say "OK", :green
                	sendJabberAlarm("SERVICE LOG RECOVER: #{svc}") if last_service_status == 'false'
	                setRedisKey(key, 'true')
                end
            rescue Exception => e
                shell.say "FAIL READING LOG", :red
                shell.say "ERROR: ", :red
                shell.say e.message
            end
        end

        # Fallen blocks
    	shell.say "CHECKING FALLEN BLOCKS", [:white, :on_blue]
        Coin.where(:active => true).where(:getBlocks => true).each do |coin|
            if coin.symbol != 'BTC'
           		shell.say "  #{coin.symbol.ljust(5)} ", :cyan
                key = "#{coin.symbol}-blocks-status"
                last_service_status = getRedisKey(key)
                last_service_status = 'false' if last_service_status.nil?
                block_count = Block.where(:coin_id => coin.id).where(:created_at.gt  => Time.new - 48.hours).count
                shell.say "#{block_count} blocks "
                if block_count > 0
                    shell.say 'OK', :green
                	sendJabberAlarm("#{coin.symbol} BLOCK RECOVER: #{block_count} blocks in last 48h") if last_service_status == 'false'
	                setRedisKey(key, 'true')
                else
                    shell.say 'FAIL', :red
                	sendJabberAlarm("PROBLEM: #{coin.symbol} NO FALLEN BLOCKS in last 48h !!!") if last_service_status == 'true'
	                setRedisKey(key, 'false')
                end
            end
       	end

	# Coin objects changes
	shell.say "CHECKING COIN OBJECTS", [:white, :on_blue]
	Coin.find_each do |coin|
		key = "coin-object-#{coin.id}"
		shell.say "  #{coin.symbol.ljust(5)} ", :cyan
		oldCoinJson = getRedisKey(key)
		changes = 0
		unless oldCoinJson.nil?
			oldCoinHash = JSON.parse(oldCoinJson, :symbolize_names => true)
            actCoinHash = JSON.parse(coin.to_json, :symbolize_names => true)
            actCoinHash.each do |key, value|
                oldValue = oldCoinHash[:"#{key}"]
                unless oldValue == value
                    shell.say("CHANGES DETECTED", :red) if changes == 0
                    changes += 1
                    shell.say "    #{key.to_s.ljust(15)} ", :green
                    shell.say "#{value} "
                    shell.say " WAS ", :blue
                    shell.say "#{oldValue} "
                    shell.say "CHANGED", :red
                	sendJabberAlarm("COIN OBJECT CHANGE!!! #{coin.symbol} changed #{key} from #{oldValue} to #{value}")
                end
            end
            if changes == 0
                shell.say("OK", :green)
            else
    			shell.say "    STORING NEW OBJECT", :yellow
                setRedisKey(key, coin.to_json)
            end
		else
			shell.say "STORING OBJECT", :yellow
			setRedisKey(key, coin.to_json)
		end
	end

        shell.say "DONE", :green

    end # End task
end # End namespace

