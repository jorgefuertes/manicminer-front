# stats_helper.rb

module StatsHelpers

    def statsRefresh(force = false)
        unless getRedisKey('stats-freshness') and force == false
            expire = 80
            logger.debug "Refreshing Stats!"
            # Request actual stats from p2pool
            result = {}
            Coin.where(:active => true, :mainChain => true).each do |coin|
                if Padrino.env == :development
                    host = 'dev.manicminer.in'
                    port = coin.poolPort
                else
                    host = coin.poolHost
                    port = coin.poolPort
                end

                begin
                    response    = HTTParty.get("http://#{host}:#{port}/local_stats")
                    parsed      = JSON.parse response.body
                    parsed[:ok] = true
                rescue Exception => e
                    parsed = {'ok' => false, 'message' => e.message}
                end
                result[coin.id] = parsed
            end

            # Store all stats in caché
            coinUp          = {}
            userUp          = {}
            workerUp        = {}
            workerSpeed     = {}
            workerDeadSpeed = {}
            userSpeed       = {}
            totalDeadSpeed  = 0
            totalSpeed      = 0
            result.each do |key, value|
                if value[:ok]
                    coinUp[key] = true
                    # Speed and activity
                    # Nook
                    value['miner_dead_hash_rates'].each do |worker, hashes|
                        worker = worker.downcase
                        user = worker.split('.')[0]
                        userUp[user] = true
                        workerUp[worker] = true
                        if workerDeadSpeed[worker].nil?
                            workerDeadSpeed[worker] = hashes
                        else
                            workerDeadSpeed[worker] += hashes
                        end
                        totalDeadSpeed += hashes
                    end
                    # Ok
                    value['miner_hash_rates'].each do |worker, hashes|
                        worker = worker.downcase
                        user = worker.split('.')[0]
                        userUp[user] = true
                        workerUp[worker] = true
                        if workerSpeed[worker].nil?
                            workerSpeed[worker] = hashes
                        else
                            workerSpeed[worker] += hashes
                        end
                        if userSpeed[user].nil?
                            userSpeed[user] = hashes
                        else
                            userSpeed[user] += hashes
                        end
                        totalSpeed += hashes
                    end
                else
                    coinUp[key] = false
                end
            end

            # To redis:
            # Complete:
            setRedisKey('last-stats', {
                    :time            => Time.now.to_i,
                    :coinUp          => coinUp,
                    :userUp          => userUp,
                    :userSpeed       => userSpeed,
                    :workerUp        => workerUp,
                    :workerSpeed     => workerSpeed,
                    :workerDeadSpeed => workerDeadSpeed,
                    :totalSpeed      => totalSpeed,
                    :totalDeadSpeed  => totalDeadSpeed
                }.to_json
            )

            # By vars:
            coinUp.each do |id, value|
                setRedisKey("coin-#{id}-up", value, expire)
            end
            userUp.each do |name, value|
                setRedisKey("user-#{name}-up", value, expire)
            end
            userSpeed.each do |name, value|
                setRedisKey("user-#{name}-speed", value, expire)
            end
            workerUp.each do |name, value|
                setRedisKey("worker-#{name}-up", value, expire)
            end
            workerSpeed.each do |name, value|
                setRedisKey("worker-#{name}-speed", value, expire)
            end
            workerDeadSpeed.each do |name, value|
                setRedisKey("worker-#{name}-dead-speed", value, expire)
            end
            setRedisKey('stats-total-speed', totalSpeed)
            setRedisKey('stats-total-dead-speed', totalDeadSpeed)

            setRedisKey('stats-freshness', Time.now.to_i, expire - 20)
        else
            logger.debug "Stats are fresh!"
        end
    end

    def hashesToHuman(kiloHashes, html = true)
        return "0BogoKhs" if kiloHashes.nil?
        kiloHashes = kiloHashes.to_f / 1000
        if html
            khsSpan = "<span class=\"bogo\">BogoKhs</span>"
            mhsSpan = "<span class=\"bogo\">BogoMhs</span>"
            ghsSpan = "<span class=\"bogo\">BogoGhs</span>"
        else
            khsSpan = " BogoKhs"
            mhsSpan = " BogoMhs"
            ghsSpan = " BogoGhs"
        end

        return "#{noFloatZero kiloHashes.round(2)}#{khsSpan}" if kiloHashes < 1000
        return "#{noFloatZero (kiloHashes/1000).round(2)}#{mhsSpan}" if kiloHashes < 1000000
        return "#{noFloatZero (kiloHashes/1000000).round(2)}#{ghsSpan}"
    end

    # Worker activity
    def isWorkerRunning(worker)
        if Padrino.env == :development
            return true if rand(100) > 50
            return false
        end

        return false if getRedisKey("worker-#{worker.user.name}.#{worker.name}-up").nil?
        return true
    end

    # Count the users who has activity
    def activeUsersCount
        if getRedisKey('active-users-count')
            return getRedisKey('active-users-count').to_i
        else
            count = 0
            User.where(:active => true).each do |user|
                count += 1 if getRedisKey("user-#{user.name}-up")
            end
            setRedisKey('active-users-count', count, 300)
        end

        return count
    end

    # Count active workers
    def activeWorkersCount
        if getRedisKey('active-workers-count')
            return getRedisKey('active-workers-count').to_i
        else
            count = 0
            Worker.find_each do |worker|
                count += 1 if isWorkerRunning worker
            end
            setRedisKey('active-workers-count', count, 300)
        end

        return count
    end

    # Stats from redis
    def getTopUsers(numberOfUsers)
        users = {}
        logger.debug "Calculating top users"
        counter = 1
        User.where(:active => true).each do |user|
            if getRedisKey("user-#{user.name}-up")
                speed = getRedisUserSpeed(user).to_f
                if speed > 0
                    logger.debug "User #{user.name} speed: #{speed}"
                    users[counter] = {:id => user.id, :name => user.name, :speed => speed}
                    counter += 1
                end
            end
        end

        users = users.sort_by {|key, value| value[:speed]}

        top = {}
        counter = 1
        users.reverse_each do |key, user|
            top[counter] = {
                :id     => user[:id],
                :name   => user[:name],
                :hashes => user[:speed],
                :speed  => hashesToHuman(user[:speed])
            }
            counter += 1
            break if counter == numberOfUsers + 1
        end

        return top
    end

    def getUsersPercent

        poolSpeed = getRedisPoolSpeed
        users = {}
        users['nouser-total'] = {:name => 'poolAdmin', :speed => poolSpeed, :percent => 100}

        logger.debug "Calculating top users"

        combinedPercent = 0.0
        combinedSpeed   = 0.0
        User.where(:active => true).each do |user|
            speed = getRedisUserSpeed(user).to_f
            if speed > 0
                percent = (speed.to_f / poolSpeed.to_f) * 100.0
                users[user.id.to_s] = {:name => user.name, :speed => speed,
                    :percent => percent}
                combinedPercent += percent
                combinedSpeed   += speed
            end
        end
        users['nouser-combined'] = {:name => 'totalCombined', :speed => combinedSpeed, :percent => combinedPercent}

        return users
    end


    def getPoolSpeed
        return getRedisKey('stats-total-speed').to_f
        return 0
    end

    def getPoolDeadSpeed
        return getRedisKey('stats-total-dead-speed').to_f
        return 0
    end

    def getUserSpeed(user)
        if getRedisKey("user-#{user.name}-up")
            return getRedisKey("user-#{user.name}-speed").to_f
        else
            return 0
        end
    end

    def getWorkerSpeed(worker)
        if getRedisKey("worker-#{worker.user.name}.#{worker.name}-up")
            return getRedisKey("worker-#{worker.user.name}.#{worker.name}-speed").to_f
        else
            return 0
        end
    end

    def getWorkerDeadSpeed(worker)
        if getRedisKey("worker-#{worker.user.name}.#{worker.name}-up")
            return getRedisKey("worker-#{worker.user.name}.#{worker.name}-dead-speed").to_f
        else
            return 0
        end
    end

    def getWorkerShares(worker)
        return getWorkerSpeed(worker)
    end

    def getProfitsTable
        if getRedisKey('coin-profit-table')
            begin
                profitsTable = JSON.parse(getRedisKey('coin-profit-table'), :symbolize_names => true)
            rescue
                return false
            end
        else
            return false
        end
    end

    def getPowerTable
        profitsTable = getProfitsTable()
        return false unless profitsTable

        powerTable = Array.new
        profitsTable.each do |symbol, data|
            powerTable << [symbol, data] unless symbol == 'BTC'
        end

        total_weight = 0
        powerTable.each do |symbol, data|
            total_weight += data[:weight] if data[:main_chain]
        end

        powerTable.each do |symbol, data|
            if data[:main_chain]
                percent = (100.to_f * data[:weight].to_f / total_weight.to_f).to_f
                data[:power_percent] = percent.round(1)
                data[:power_khs] = (1000000 * percent / 100).round(2)
                data[:reward] = (data[:reward] / 100 * percent)
                data[:btc_reward] = (data[:btc_reward] / 100 * percent)
            else
                data[:power_percent] = 100
                data[:power_khs] = 1000000
            end
        end

        return powerTable
    end

    def btcValue(amount, symbol)
        profitsTable = getProfitsTable()
        return 0 unless profitsTable
        return 0 if amount.is_a? String
        profitsTable.each do |key, data|
            unless data[:last_btc_rate].is_a? String
                return data[:last_btc_rate] * amount if key == symbol
            end
        end
        return 0
    end

    def btcMinValue(amount, symbol)
        profitsTable = getProfitsTable()
        return 0 unless profitsTable
        return 0 if amount.is_a? String
        profitsTable.each do |key, data|
            unless data[:lowest_btc_rate].is_a? String
                return data[:lowest_btc_rate] * amount if key == symbol
            end
        end
        return 0
    end

    # --- LEGACY ---
    def getRedisPoolSpeed
        return getPoolSpeed()
    end
    def getRedisWorkerShares(worker)
        return getWorkerSpeed(worker)
    end
    def getRedisWorkerSpeed(worker)
        return getWorkerSpeed(worker)
    end
    def getRedisUsersPercent
        return getUsersPercent()
    end
    def getRedisUserSpeed(user)
        return getUserSpeed(user)
    end
    def getRedisTopUsers(numberOfUsers)
        return getTopUsers(numberOfUsers)
    end
end

ManicminerPool::App.helpers StatsHelpers
