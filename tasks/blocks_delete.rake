# blocks_delete.rake

namespace :blocks do
    desc "Delete coin's all blocks"
    task :delete => :environment do
        logger.level = 4

        at_exit do
            shell.say "Ok. Bye!"
        end

        shell.say "\n"
        shell.say "Delete ALL BLOCKS from a coin", [:black, :on_cyan]
        shell.say "\n"
        shell.say "COINS:", :yellow
        Coin.find_each do |coin|
            shell.say "#{coin.symbol} ", :cyan
            shell.say "#{coin.name} "
            shell.say("ACTIVE ", :green) if coin.active
            shell.say("INACTIVE ", :red) unless coin.active
            shell.say "has #{coin.blocks.count} blocks"
        end

        shell.say "\n"
        symbol = shell.ask "Delete from coin with symbol? "

        coin = Coin.where(:symbol => symbol).first
        unless coin
            shell.error "Coin '#{symbol}' not found!"
            exit
        end

        shell.say "*** WARNING: Operation cannot be undoned! ***", :red

        unless shell.yes?("Really delete ALL BLOCKS from #{symbol}?")
            shell.error "Canceled"
            exit
        end

        shell.say "Destroying #{coin.blocks.count} blocks... "
        coin.blocks.delete_all
        shell.say "OK", :green
        shell.say "#{symbol} has #{coin.blocks.count} blocks now."

    end # End task
end # End namespace
