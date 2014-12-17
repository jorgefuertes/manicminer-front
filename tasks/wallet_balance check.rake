# Wallet balance check

namespace :wallet do
    desc 'Recalculate all wallets from transactions'
    task :balance_check => :environment do
        logger.level = 4
        include RedisHelpers
        include CoindHelpers
        include UiHelpers

        shell.say "COINS:", :yellow
        Coin.find_each do |coin|
            shell.say "#{coin.symbol.ljust(5)} ", :cyan
            shell.say("* ", :green) if coin.active
            shell.say("- ", :red) unless coin.active
            shell.say "#{coin.name}"
        end

        symbol = shell.ask "ReCalc transactions of symbol? "
        symbol = symbol.upcase
        coin = Coin.where(:symbol => symbol).first
        unless coin
            shell.error "Coin '#{symbol}' not found!"
            exit
        end

        Wallet.where(:coin_id => coin.id).each do |wallet|
            shell.say "#{wallet.user.name.ljust(25)}: ", :cyan
            balance = 0.0
            wallet.transactions.each do |tx|
                balance += tx.amount
                #shell.say "  #{floatToHuman tx.amount} ", :red if tx.amount < 0
                #shell.say "  #{floatToHuman tx.amount} ", :green if tx.amount > 0
                #shell.say "#{tx.coin.symbol} ", :yellow
                #shell.say "#{tx.dtnAddress}", :blue
            end
            #shell.say "  TOTAL BALANCE: ", :yellow
            shell.say " #{(floatToHuman balance).to_s.rjust(15)} ", [:white, :on_blue]
            shell.say
        end

        shell.say "DONE", :green

    end # End task
end # End namespace
