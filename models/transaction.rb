class Transaction
  include MongoMapper::Document
  safe

  belongs_to :user, :required => true
  belongs_to :wallet, :required => true
  belongs_to :coin, :required => true

  # key <name>, <type>
  key :amount, Float, :required => true
  key :dtnAddress, String, :required => true
  key :fee, Float, :required => true
  key :comments, String, :default => "TRANSFER"
  key :total, Float, :required => false
  key :internalId, String, :default => "NONE"

  timestamps!

  before_validation :complete

  private
  	def complete
  		self.coin_id = self.wallet.coin_id if self.coin_id.nil?
  		self.user_id = self.wallet.user_id if self.user_id.nil?
  		self.fee  = Coin.find(self.wallet.coin_id).txFee  if self.fee.nil?
  		self.dtnAddress = self.wallet.address if self.dtnAddress.nil?
  	end
end
