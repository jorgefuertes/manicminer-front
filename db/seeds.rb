# Seed add you the ability to populate your db.

logger.level = 4

shell.say
shell.say "+--[*** DESTROY DATABASE ***]-------------+"
shell.say "| Do you want to destroy actual contents? |"
shell.say "+-----------------------------------------+"
shell.say
confirm = shell.ask("Say 'yes' if you're really sure: ")
shell.say 'Aborted' unless confirm == 'yes'
exit unless confirm == 'yes'

shell.say
shell.say "Ok, as you whish!"
shell.say

Token.remove
Wallet.remove
Worker.remove
Account.remove
Coin.remove

shell.say "+ Admin accounts:"
admins = {
	:one => {
		:email    => 'userone@domain.com',
		:name     => 'userone',
		:password => 'somepass'
	},
	:two => {
		:email    => 'usertwo@domain.com',
		:name     => 'usertwo',
		:password => 'somepass'
	}
}

admins.each do |key, data|
	shell.say "  - #{key}: #{data[:email]}"
	user = User.first(:email => data[:email])
	if user
		shell.say "    Already exists!"
	else
		data[:role] = 'admin'
		data[:password_confirmation] = data[:password]
		data[:emailConfirm] = true
		data[:active] = true
		user = User.create(data)
		if user.save
			shell.say "    OK: #{user.id}"
		else
			shell.say "    ERROR: #{user.errors.full_messages.inspect}"
		end
	end
end

shell.say "+ Coins:"
coins = {
	:ltc  => {
		:name => 'LiteCoin',
		:symbol => 'LTC',
		:url => 'https://litecoin.info',
		:mainChain => true,
		:rpcUser => 'litecoinrpc', :rpcPass => 'somepass', :rpcPort => '15001', :rpcHost => 'localhost',
		:port => 3333
	},
	:dgc  => {
		:name => 'DogeCoin',
		:symbol => 'DGC',
		:url => 'http://dogecoins.info',
		:mainChain => true,
		:rpcUser => 'dogecoinrpc', :rpcPass => 'somepass', :rpcPort => '15002',
		:rpcHost => 'localhost',
		:port => 4444
	},
	:ptc  => {
		:name => 'PesetaCoin',
		:symbol => 'PTC',
		:url => 'http://pesetacoin.info',
		:mainChain => false,
		:rpcUser => 'pesetacoinrpc', :rpcPass => 'somepass', :rpcPort => '15003', :rpcHost => 'localhost'
	},
	:usc  => {
		:name => 'UnitedScryptCoin',
		:symbol => 'USC',
		:url => 'http://usc.ax.lt',
		:mainChain => false,
		:rpcUser => 'unitedscryptcoinrpc', :rpcPass => 'somepass', :rpcPort => '15004', :rpcHost => 'localhost'
	},
	:org  => {
		:name => 'OrgCoin',
		:symbol => 'ORG',
		:url => 'http://www.orgcoin.org',
		:mainChain => false,
		:rpcUser => 'orgcoinrpc', :rpcPass => 'somepass', :rpcPort => '15005', :rpcHost => 'localhost'
	},
	:hunt => {
		:name => 'HunterCoin',
		:symbol => 'HUNT',
		:url => 'https://github.com/chronokings/huntercoin',
		:mainChain => false,
		:rpcUser => 'hunterrpc', :rpcPass => 'somepass', :rpcPort => '15006', :rpcHost => 'localhost'
	}
}

coins.each do |key, data|
	shell.say "  - #{key}: #{data[:name]}"
	coin = Coin.first(:symbol => data[:symbol])
	if coin
		shell.say "    Already exists!"
	else
		coin = Coin.create(data)
		if coin.save
			shell.say "    OK: #{coin.id}"
		else
			shell.say "    ERROR: #{coin.errors.full_messages.inspect}"
		end
	end
end

shell.say "> EOF."
