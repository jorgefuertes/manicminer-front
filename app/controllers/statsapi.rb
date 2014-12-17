ManicminerPool::App.controllers :statsapi do

  get 'pool/speed', :provides => :json do
    return {:speed => (getRedisPoolSpeed.to_f / 1000), :unit => 'khs'}.to_json
  end

  get 'general', :provides => :json do
    key = 'general-stats-json'
    unless getRedisKey(key)
		totalUsers           = User.where(:active => true, :emailConfirm => true).count
		unconfirmedUsers     = User.where(:emailConfirm => false).count
		activeUsers          = activeUsersCount
		activeUsersPercent   = activeUsers * 100 / totalUsers
		totalWorkers         = Worker.count
		activeWorkers        = activeWorkersCount
		activeWorkersPercent = activeWorkers * 100 / totalWorkers
		totalWallets         = Wallet.count
		activeWallets        = Wallet.where(:active => true).count
		activeWalletsPercent = activeWallets * 100 / totalWallets
		users                = getTopUsers(20)

		counter = 0
		avg_power_sum = 0.0
		HourlyStats.where(:created_at.gt => Time.now.utc - 2.day).each do |h|
			counter += 1
			avg_power_sum += h.avgSpeed
		end
		avg_power = avg_power_sum / counter

  		stats = {
  			:totals => {
	  			:total_power       => hashesToHuman(getPoolSpeed),
	  			:avg_power         => hashesToHuman(avg_power),
	  			:total_dead_power  => hashesToHuman(getPoolDeadSpeed),
	  			:total_users       => totalUsers,
	  			:unconfirmed_users => unconfirmedUsers,
	  			:active_users      => "#{activeUsers} (#{activeUsersPercent}%)",
	  			:total_workers     => totalWorkers,
	  			:active_workers    => "#{activeWorkers} (#{activeWorkersPercent}%)",
	  			:total_wallets     => totalWallets,
	  			:active_wallets    => "#{activeWallets} (#{activeWalletsPercent}%)",
	  			:blocks            => Block.where(:confirmed => true).count
	  		},
  			:users           => users
  		}.to_json

  		setRedisKey(key, stats, 120)
  	end

    return getRedisKey(key)
  end

  get 'coin/values', :provides => :json do
    output = Array.new
    Coin.where(:active => true).each do |coin|
    	unless coin.symbol == 'BTC'
			output << {
				:symbol   => coin.symbol,
				:color    => coin.colorClass,
				:name     => coin.name,
				:trend    => getCoinTrending(coin),
				:btc_rate => floatToHuman(getCacheBtcLastRate(coin))
			}
		end
    end

    return output.to_json
  end

  get 'coin/ticker' do
  	return partial 'partials/coin-ticker'
  end

  # -------------------- CHARTS --------------------------------

  get 'charts/speed/last-hours', :provides => :json do
  	labels = Array.new
  	speed_min = Array.new
  	speed_max = Array.new
  	speed_avg = Array.new

  	HourlyStats.where(:created_at.gt => Time.now.utc - 1.day).each do |h|
  		labels << "#{h.hour.to_s.rjust(2, '0')}:00"
  		speed_min << h.minSpeed / 1000000.0
  		speed_max << h.maxSpeed / 1000000.0
  		speed_avg << h.avgSpeed / 1000000.0
  	end

  	return speedChart(labels, speed_min, speed_avg, speed_max)
  end

  get 'charts/speed/last-minutes', :provides => :json do
  	labels = Array.new
  	speed_avg     = Array.new
  	actual_hour   = Time.now.utc.strftime("%H").to_i
  	previous_hour = actual_hour - 1
  	previous_hour = 23 if previous_hour < 0
  	actual_minute = Time.now.utc.strftime("%M").to_i
  	minutes = Array(0..59)
  	minutes.rotate!(actual_minute - 59)

  	last = 0
	minutes.each do |m|
		if m <= actual_minute
			h = actual_hour
		else
			h = previous_hour
		end
		time_string = "#{h.to_s.rjust(2, '0')}:#{m.to_s.rjust(2, '0')}"
		labels << time_string
		if getRedisKey("stats-minute-#{time_string}")
			stats = JSON.parse(getRedisKey("stats-minute-#{time_string}"), :symbolize_names => true)
			speed_avg << stats[:speed].to_f / 1000000.0
			last = stats[:speed].to_f / 1000000.0
		else
			speed_avg << last
		end
	end

	return singleChart(labels, speed_avg)
  end

  get 'charts/speed/last-week', :provides => :json do
  	key = 'chart-week-speed'
  	if getRedisKey(key)
  		return getRedisKey(key)
  	else
  		data = daysChart 7, '%a %d'
  		setRedisKey(data, 12 * 60 * 60)
  		return data
  	end
  end

  get 'charts/speed/last-month', :provides => :json do
  	key = 'chart-month-speed'
  	if getRedisKey(key)
  		return getRedisKey(key)
  	else
  		data = daysChart 30, '%d'
  		setRedisKey(data, 12 * 60 * 60)
  		return data
  	end
  end
end

# Days Chart
def daysChart(num_days = 7, time_label = '%a %d')
  	labels = Array.new
  	speed_min = Array.new
  	speed_max = Array.new
  	speed_avg = Array.new
  	speed_min_sum = 0.0
  	speed_max_sum = 0.0
  	speed_avg_sum = 0.0

  	last_date = ""
  	counter = 0
  	HourlyStats.where(:created_at.gt => Time.now.utc - (num_days - 1).day).each do |h|
  		if last_date == ""
  			logger.debug "First date: #{h.created_at}"
	  		labels << h.created_at.strftime(time_label)
	  		last_date = h.created_at.strftime "%d-%m-%Y"
	  	end
  		if h.created_at.strftime("%d-%m-%Y") == last_date
  			logger.debug "Record #{counter}: min #{h.minSpeed} avg #{h.avgSpeed} max #{h.maxSpeed}"
		  	speed_min_sum += h.minSpeed
		  	speed_max_sum += h.maxSpeed
		  	speed_avg_sum += h.avgSpeed
		  	counter += 1
  		else
  			logger.debug "--- New date: #{h.created_at} ---"
	  		labels << h.created_at.strftime(time_label)
	  		min = speed_min_sum / counter / 1000000.0 if speed_min_sum > 0
	  		min = 0 if speed_min_sum <= 0
	  		max = speed_max_sum / counter / 1000000.0 if speed_max_sum > 0
	  		max = 0 if speed_max_sum <= 0
	  		avg = speed_avg_sum / counter / 1000000.0 if speed_max_sum > 0
	  		avg = 0 if speed_avg_sum <= 0
  			speed_min << min
	  		speed_max << max
  			speed_avg << avg
		  	speed_min_sum = 0.0
		  	speed_max_sum = 0.0
		  	speed_avg_sum = 0.0
  			last_date = h.created_at.strftime "%d-%m-%Y"
  			counter = 0
  		end
  	end
  	if counter > 0
  		min = speed_min_sum / counter / 1000000.0 if speed_min_sum > 0
  		min = 0 if speed_min_sum <= 0
  		max = speed_max_sum / counter / 1000000.0 if speed_max_sum > 0
  		max = 0 if speed_max_sum <= 0
  		avg = speed_avg_sum / counter / 1000000.0 if speed_max_sum > 0
  		avg = 0 if speed_avg_sum <= 0
		speed_min << min
  		speed_max << max
		speed_avg << avg
	end

  	return speedChart(labels, speed_min, speed_avg, speed_max)
end

# Plain chart
def singleChart(labels, data)
  	return {
  		:labels => labels,
  		:datasets => [{
			:fillColor        => "rgba(151, 187, 205, .5)",
			:strokeColor      => "rgba(151, 187, 205, 1)",
			:pointColor       => "rgba(151, 187, 205, 1)",
			:pointStrokeColor => "rgba(0, 0 , 0, .4)",
			:title            =>  t('pages.charts.avg'),
			:data             => data
  		}]
  	}.to_json
end

# Return a JSON speed chart
def speedChart(labels, speed_min, speed_avg, speed_max)
  	return {
  		:labels => labels,
  		:datasets => [
  			{
				:fillColor        => "rgba(244, 193, 207, 0.6)",
				:strokeColor      => "rgba(244, 193, 207, 1)",
				:pointColor       => "rgba(244, 193, 207, 1)",
				:pointStrokeColor => "rgba(0, 0 , 0, .4)",
				:title            => t('pages.charts.max'),
				:data             => speed_max
  			},
  			{
				:fillColor        => "rgba(151,187,205, 0.5)",
				:strokeColor      => "rgba(151,187,205, 1)",
				:pointColor       => "rgba(151,187,205, 1)",
				:pointStrokeColor => "rgba(0, 0 , 0, .4)",
				:title            =>  t('pages.charts.avg'),
				:data             => speed_avg
  			},
  			{
				:fillColor        => "rgba(224, 224, 224, .5)",
				:strokeColor      => "rgba(224, 224, 224, 1)",
				:pointColor       => "rgba(224, 224, 224, 1)",
				:pointStrokeColor => "rgba(0, 0 , 0, .4)",
				:title            =>  t('pages.charts.min'),
				:data             => speed_min
  			}
  		]
  	}.to_json
end
