namespace :db do
    desc 'Generate fake transactions'
    task :faketrans => :environment do
        logger.level = 4

        if Padrino.env != :development
            shell.say "\n\n"
            shell.say "Only at production environment!", [:white, :on_red]
            shell.say "Use as: "
            shell.say "padrino -e production coin:force_payouts", :cyan
            shell.say "\n"
            exit
        end

		shell.say
		shell.say "+--[*** ONLY AT DEV MODE ***]----------------+"
		shell.say "| Do you want to generate fake transactions? |"
		shell.say "+--------------------------------------------+"
		shell.say
		confirm = shell.ask("Say 'yes' if you're really sure: ")
		shell.say 'Aborted' unless confirm == 'yes'
		exit unless confirm == 'yes'

		shell.say
		shell.say "Ok, as you whish!"
		shell.say

		user = User.where(:name => 'queru').first
		raise "No user!" unless user
		shell.say "> Generating fake transactions for user #{user.name}: #{user.id}"

		user.wallets.each do |wallet|
			shell.say "  + Wallet: #{wallet.name}"
			(1..1000).each do |index|
	            trans = Transaction.create(:wallet => wallet, :amount => -wallet.coin.txFee, :fee => 0, :comments => 'FEE')
	   			shell.say "  - New trans: #{index} #{trans.id}"
    	        Transaction.create(:wallet => wallet, :amount => -rand(50000), :comments => 'PAYOUT')
	   			shell.say "  - New trans: #{index} #{trans.id}"
			end
		end

		shell.say "> EOF."
	end
end
