# Custom task to do autopayments

namespace :coin do
    desc 'Update coin change values'
    task :update_changes => :environment do
        logger.level = 4
        include RedisHelpers
        include CoindHelpers
        include StatsHelpers
        include ExchangeHelpers

        if Padrino.env != :production and Padrino.env != :development
            shell.say "\n\n"
            shell.say "Unknown environment!", [:white, :on_red]
            shell.say "Use as: "
            shell.say "padrino -e production coin:force_payment", :cyan
            shell.say "\n"
            exit
        end

        trap("SIGINT") do
            shell.say ""
            shell.say "User interrupted.", :red
            shell.say "Bye!", :yellow
            shell.say ""
            exit!
        end

        # --- BEGIN ---
        while true do
            shell.say
            shell.say "COINS CHANGES:", [:white, :on_blue]
            shell.say "+#{'-' * 114}+"
            shell.say "| "
            shell.say "ID#{' ' * 23}", :cyan
            shell.say "| "
            shell.say "SYM  ", :cyan
            shell.say "| "
            shell.say "NAME     ", :cyan
            shell.say "| "
            shell.say "AC ", :cyan
            shell.say "| "
            shell.say "LAST            ", :cyan
            shell.say "| "
            shell.say "LOWEST BTC RATE ", :cyan
            shell.say "| "
            shell.say "TRD ", :cyan
            shell.say "| "
            shell.say "TIME       ", :cyan
            shell.say "| "
            shell.say "EXCHG   ", :cyan
            shell.say "|"
            shell.say "+#{'-' * 114}+"

            coinTable = Hash.new

            Coin.find_each do |coin|
                lastRate   = 0
                lowestRate = 0
                exchange   = 'none'

                rates      = getBtcAllRates(coin)
                lastRate   = rates[:last]
                lowestRate = rates[:lowest]
                exchange   = rates[:exchange]
                timestamp  = Time.now.to_i

                # Carry on last cache data if new rate is 0
                lastRate = getCacheBtcLastRate(coin) if lastRate == 0
                lowestRate = getCacheBtcLowestRate(coin) if lowestRate == 0

                begin
                    if getCacheBtcLastRate(coin) < lastRate
                        trend = '+'
                    elsif getCacheBtcLastRate(coin) == lastRate
                        trend = '='
                    else
                        trend = '-'
                    end
                rescue
                    trend = '='
                end

                coinTable[coin.symbol] = {
                    :id              => coin.id,
                    :last_btc_rate   => lastRate,
                    :lowest_btc_rate => lowestRate,
                    :trend           => trend,
                    :time            => timestamp,
                    :exchange        => exchange
                }

                shell.say "| "
                shell.say "#{coin.id} ", :cyan
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
                shell.say "#{format("%.10f", lowestRate).rjust(15)} ", :yellow
                shell.say "| "
                shell.say(" +  ", :green) if trend == '+'
                shell.say(" =  ", :blue) if trend == '='
                shell.say(" -  ", :red) if trend == '-'
                shell.say "| "
                shell.say "#{timestamp} ", :blue
                shell.say "| "
                shell.say "#{exchange[0..6].ljust(7)} "
                shell.say "|"
            end
            shell.say "+#{'-' * 114}+"

            shell.say "> To redis "
            shell.say "coin-changes-table ", :cyan
            shell.say ": "
            setRedisKey('coin-changes-table', coinTable.to_json)
            shell.say "OK", :green
            shell.say "> Sleeping 5 minutes..."
            sleep 300
            shell.say "> AWAKEN!", :green
        end # Main loop
    end # End task
end # End coin
