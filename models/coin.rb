class Coin
  include MongoMapper::Document

  many :wallets
  many :blocks
  many :transactions

  # key <name>, <type>
  key :name, String, :required => true
  key :symbol, String, :required => true
  key :url, String, :format => URI::regexp(%w(http https))
  key :urlWallets, String, :required => false, :format => URI::regexp(%w(http https))
  key :rpcUser, String
  key :rpcPass, String
  key :rpcPort, Integer
  key :rpcHost, String
  key :poolHost, String, :default => 'localhost'
  key :poolPort, Integer, :default => 0
  key :active, Boolean, :default => true
  key :mainChain, Boolean, :default => false
  key :txFee, Float, :default => 0
  key :port, Integer, :default => 3333
  key :integerOnly, Boolean, :default => false
  key :confirms, Integer, :default => 50
  key :blockExplorer, String, :required => false
  key :colorClass, String, :default => 'zx-black'
  key :blockValue, Float, :default => 50
  key :getBlocks, Boolean, :default => true
  key :autoShare, Boolean, :default => true
  key :tradeOn, Boolean, :default => true
  key :powerOn, Boolean, :default => true

  timestamps!

  validates_uniqueness_of :symbol

end
