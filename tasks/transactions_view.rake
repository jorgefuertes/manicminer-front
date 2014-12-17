namespace :transactions do
    desc 'Look and view transactions'
    task :view => :environment do
        logger.level = 4
        include UiHelpers

        if Padrino.env != :production and Padrino.env != :development
            shell.say "\n\n"
            shell.say "Unknown environment!", [:white, :on_red]
            shell.say "Use as: "
            shell.say "padrino -e production coin:force_payment", :cyan
            shell.say "\n"
            exit
        end

        shell.say "COINS:", :yellow
        Coin.find_each do |coin|
            shell.say "#{coin.symbol.ljust(5)} ", :cyan
            shell.say("* ", :green) if coin.active
            shell.say("- ", :red) unless coin.active
            shell.say "#{coin.name}"
        end

        symbol = shell.ask "View transactions of symbol? "
        symbol = symbol.upcase
        coin = Coin.where(:symbol => symbol).first
        unless coin
            shell.error "Coin '#{symbol}' not found!"
            exit
        end

        shell.say "You can use regexp like 'FORCED|TRADE', or single text...", :yellow
        text = shell.ask "Text to search? "

        counter = 0
        regexp = /(#{text}).*/i
        shell.say "> Looking for "
        shell.say "#{coin.symbol} ", :cyan
        shell.say "transactions with comment filter: "
        shell.say "#{regexp.to_s}", :magenta
        Transaction.where(:coin_id => coin.id).where(:comments => regexp).each do |t|
            counter += 1
            shell.say "#{t.created_at} ", :blue
            shell.say "#{t.user.name} "
            shell.say "#{t.dtnAddress} ", :yellow
            if t.amount > 0
                shell.say "#{floatToHuman t.amount} ", :green
            else
                shell.say "#{t.amount} ", :red
            end
            shell.say "#{t.comments}", :magenta
        end
        shell.say "> #{counter} ", :green
        shell.say "transactions found."
    end
end
