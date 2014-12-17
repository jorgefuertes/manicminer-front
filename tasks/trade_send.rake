# trade_send.rake

namespace :trade do
    desc 'Send all coins to configured trade address'
    task :send => :environment do
        logger.level = 4
        include CoindHelpers
        include UiHelpers

        config_file = "#{Padrino.root}/config/tradeconf.yml"
        shell.say "> Loading "
        shell.say "tradeconf.yml ", :yellow
        begin
            destinations = YAML::load(File.open(config_file))['destinations']
        rescue Exception => e
            shell.say "PARSE ERROR", :red
            shell.say "ERROR: ", :red
            shell.say e.message
            exit 1
        end
        shell.say "OK", :green

        account = shell.ask "> Enter the account to be emptied (defaults to btctrade): "
        account = 'btctrade' if account == ""

        user = User.where(:name => account).first
        unless user
            shell.say "ERROR: ", :red
            shell.say "Account #{account} not found at database!"
            exit 1
        end

        shell.say "••• #{account} SEND PREVIEW •••", [:white, :on_blue]
        destinations.each do |symbol, data|
            address = data['address']
            send    = data['send']
            coin = Coin.first(:symbol => symbol.to_s)
            unless coin
                shell.say "ERROR: ", :red
                shell.say "Coin #{symbol} not found at database!"
                exit 1
            end

            wallet = user.wallets.first(:coin_id => coin.id)
            balance = getWalletBalance(wallet)
            shell.say "#{symbol.to_s.ljust(6)} ", :cyan
            shell.say "#{floatToHuman(balance).to_s.rjust(20)} "
            shell.say "#{address} "
            if send
                shell.say "SEND", :green
            else
                shell.say "DON'T SEND", :blue
            end
        end

        shell.say "••• HAZARDOUS OPERATION: PAY ATTENTION •••", [:white, :on_red]
        unless shell.yes?("Really do the send operations?")
            shell.error "Canceled"
            exit
        end

        shell.say "••• #{account} SENDING FUNDS •••", [:white, :on_blue]
        destinations.each do |symbol, data|
            address = data['address']
            send    = data['send']
            if send
                coin = Coin.first(:symbol => symbol.to_s)
                unless coin
                    shell.say "ERROR: ", :red
                    shell.say "Coin #{symbol} not found at database!"
                    exit 1
                end

                wallet = user.wallets.first(:coin_id => coin.id)
                balance = getWalletBalance(wallet)
                shell.say "#{symbol.to_s.ljust(6)} ", :cyan
                shell.say "#{floatToHuman(balance).to_s.rjust(20)} "
                shell.say "#{address} "

                if balance > 0
                    begin
                        coinClient = getCoinClient(coin)
                        coinClient.sendfrom(wallet.user.name, address, balance)
                        Transaction.create(
                            :wallet     => wallet,
                            :amount     => -balance,
                            :dtnAddress => address,
                            :fee        => 0.0,
                            :total      => 0.0,
                            :comments   => 'SEND TO EXCHANGE'
                        )
                        shell.say "SENDED", :green
                    rescue Exception => e
                        shell.say "FAIL", :red
                        shell.say "ERROR: ", :red
                        shell.say e.message
                    end
                else
                    shell.say "NO BALANCE", :yellow
                end
            end
        end

        shell.say "> "
        shell.say "Completed", :green

    end # End task
end # End namespace
