# Custom task to do autopayments

namespace :coin do
    desc 'Get coin frofitability'
    task :get_profitability => :environment do
        logger.level = 4
        include RedisHelpers
        include CoindHelpers
        include StatsHelpers
        include ExchangeHelpers
        include JabberHelpers

        # Config:
        cfg_orig_name     = '/etc/haproxy/haproxy.cfg'
        cfg_template_name = 'config/haproxy.cfg.template'
        cfg_new_name      = 'config/haproxy.cfg.new'
        cfg_old_name      = 'config/haproxy.cfg.old'
        ha_host           = 's4.martianoids.com'

        if Padrino.env != :production and Padrino.env != :development
            shell.say "\n\n"
            shell.say "Unknown environment!", [:white, :on_red]
            shell.say "Use as: "
            shell.say "padrino -e production coin:force_payment", :cyan
            shell.say "\n"
            exit
        end

        # --- BEGIN ---
        while true do
            shell.say
            shell.say "COINS PROFITABILITY:", [:white, :on_blue]
            shell.say "+#{'-' * 112}+"
            shell.say "| "
            shell.say "SYM  ", :cyan
            shell.say "| "
            shell.say "NAME     ", :cyan
            shell.say "| "
            shell.say "AC ", :cyan
            shell.say "| "
            shell.say "BTC/1           ", :cyan
            shell.say "| "
            shell.say "DIFF            ", :cyan
            shell.say "| "
            shell.say "BLKVAL          ", :cyan
            shell.say "| "
            shell.say "REWARD          ", :cyan
            shell.say "| "
            shell.say "BTC/REWD        ", :cyan
            shell.say "|"
            shell.say "+#{'-' * 112}+"

            coinTable = Hash.new
                                        
            Coin.where(:active => true).where(:powerOn => true).find_each do |coin|
                begin
                    lastRate   = getCacheBtcLastRate(coin)
                    lowestRate = getCacheBtcLowestRate(coin)
                    coinReward = getReward(coin, 1000)
                    btcReward  = coinReward * lastRate
                    blockValue = getBlockValue(coin)
                    difficulty = getDifficulty(coin)
                rescue Exception => e
                    shell.error "ERROR on #{coin.symbol}: #{e.message}"
                    lastRate   = 0
                    lowestRate = 0
                    coinReward = 0
                    btcReward  = 0
                    blockValue = 0
                end

                coinTable[coin.symbol] = {
                    :last_btc_rate   => lastRate,
                    :lowest_btc_rate => lowestRate,
                    :reward          => coinReward,
                    :block_value     => blockValue,
                    :btc_reward      => btcReward,
                    :main_chain      => coin.mainChain,
                    :difficulty      => difficulty,
                    :weight          => 0,
                    :pool            => "#{coin.poolHost}:#{coin.poolPort}"
                }

                shell.say "| "
                shell.say "#{coin.symbol[0..3].ljust(4)} ", :cyan
                shell.say "| "
                shell.say "#{coin.name[0..7].ljust(8)} ", :white if coin.mainChain
                shell.say "#{coin.name[0..7].ljust(8)} ", :yellow unless coin.mainChain
                shell.say "| "
                shell.say("*  ", :green) if coin.active
                shell.say("-  ", :red) unless coin.active
                shell.say "| "
                shell.say "#{format("%.10f", lastRate).rjust(15)} ", :yellow
                shell.say "| "
                shell.say "#{format("%.10f", difficulty).rjust(15)} ", :green
                shell.say "| "
                shell.say "#{format("%.8f", blockValue).rjust(15)} ", :white
                shell.say "| "
                shell.say "#{format("%.10f", coinReward).rjust(15)} ", :magenta
                shell.say "| "
                shell.say "#{format("%.10f", btcReward).rjust(15)} ", :red
                shell.say "|"
            end
            shell.say "+#{'-' * 112}+"

            # Calculate weights
            # HAProxy config
            cfgTxt = ""
            shell.say "Weight table:", [:white, :on_blue]
            coinSortedTable = coinTable.sort_by{|k,v| v[:btc_reward]}
            weight = 1
            shell.say "+#{'-' * 30}+"
            coinSortedTable.each do |coinSymbol, data|
                if data[:main_chain] == true
                    data[:weight] = weight
                    weight += 1
                    shell.say "| "
                    shell.say "#{coinSymbol[0..3].ljust(4)} ", :cyan
                    shell.say "| "
                    shell.say "#{data[:weight].to_s.rjust(3)} "
                    shell.say "| "
                    shell.say "#{format("%.10f", data[:btc_reward]).rjust(15)} ", :red
                    shell.say "|"
                    cfgTxt << ' ' * 8
                    cfgTxt << "server #{coinSymbol.ljust(5)} "
                    cfgTxt << "#{data[:pool]} "
                    cfgTxt << "weight #{data[:weight].to_s} "
                    cfgTxt << "check inter 15000"
                    cfgTxt << "\n"
                end
            end
            shell.say "+#{'-' * 30}+"

            shell.say "> Generating HAProxy config: ", :yellow

            newCfg = File.open(cfg_new_name, 'w')
            File.open(cfg_template_name, 'r') do |file|
                while line = file.gets
                    wrline = line
                    wrline = cfgTxt if /\#\{SERVERS\}/.match(line)
                    newCfg.write wrline
                end
            end
            newCfg.close
            shell.say "OK", :green

            FileUtils.cp(cfg_template_name, cfg_old_name) unless File.exist?(cfg_old_name)

            shell.say "> Compare files: "
            if FileUtils.cmp(cfg_new_name, cfg_old_name)
                shell.say "IDENTICAL", :green
                shell.say "> No futher action required"
            else
                shell.say "DIFFERENT", :RED
                shell.say "> Copying new file to HA machine: "
                begin
                    Net::SCP.start(ha_host, 'root', :keys => '/root/.ssh/id_rsa') do|scp|
                        scp.upload!(cfg_new_name, cfg_orig_name)
                    end
                    shell.say "OK", :green
                rescue Exception => e
                    shell.say "FAIL", :red
                    shell.say e.message
                    sendJabberAlarm("Get profitability error: #{e.message}")
                end

                begin
                    shell.say "> Restarting HAProxy: ", :yellow
                    Net::SSH.start(ha_host, 'root', :keys => '/root/.ssh/id_rsa') do|ssh|
                        ssh.exec!('pkill -9 haproxy')
                    end
                    shell.say "OK", :green
                rescue Exception => e
                    shell.say "FAIL", :red
                    shell.say e.message
                    sendJabberAlarm("Get profitability error: #{e.message}")
                end

                FileUtils.cp(cfg_new_name, cfg_old_name)
            end
            shell.say "> To redis: "
            setRedisKey('coin-profit-table', coinSortedTable.to_json)
            shell.say "OK", :green
            shell.say "> Sleeping 1 hour..."
            sleep 60 * 60
            shell.say "> AWAKEN!", :green
        end # Main loop
    end # End task
end # End coin
