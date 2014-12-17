# redis_helper.rb

module RedisHelpers

	# Puts a redis key
	def setRedisKey(key, value, expire_in_secs = 0)
		counter = 0
		ok = false
		while ok == false
			begin
				redis = Redis.new
				redis.set(key, value)
				redis.expireat(key, Time.now.to_i + expire_in_secs) if expire_in_secs > 0
				ok = true
			rescue
				counter =+1
                if counter > 20
                    raise "Redis doesn't reply at #{counter} tries!"
                    break
                end
                sleep 0.25
			end
		end
	end

	# Delete a key
	def delRedisKey(key)
		redis = Redis.new
		redis.del key
	end

    # Gets a redis key taking control over timeouts
    def getRedisKey(key)
        value = nil
        ok = false
        counter = 0

        while ok == false
            begin
                redis = Redis.new
                value = redis.get key
                ok = true
            rescue
                counter += 1
                if counter > 20
                    raise "Redis doesn't reply at #{counter} tries!"
                    break
                end
                sleep 0.25
            end
        end

        return value
    end # getRedisKey

    def getRedisHkeys(key)
        value = nil
        ok = false
        counter = 0

        while ok == false
            begin
                redis = Redis.new
                value = redis.hkeys key
                ok = true
            rescue
                counter += 1
                if counter > 20
                    raise "Redis doesn't reply at #{counter} tries!"
                    break
                end
                sleep 0.25
            end
        end

        return value
    end # getRedisHkeys

end # module

ManicminerPool::App.helpers RedisHelpers
