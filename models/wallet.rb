class Wallet
  include MongoMapper::Document

  belongs_to :user
  belongs_to :coin
  many :transactions

  # key <name>, <type>
  key :name, String
  key :active, Boolean, :default => false
  key :address, String
  key :payOn, Float, :default => 0

  timestamps!

  validate :custom_validation

  def custom_validation
    if payOn > 50000
      errors.add(:payOn, 'Max payOn is 50000')
    end
  end

end
