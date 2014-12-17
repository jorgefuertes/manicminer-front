class Block
  include MongoMapper::Document

  belongs_to :coin

  # key <name>, <type>
  key :hash, String, :required => true
  key :height, Integer
  key :amount, Float
  key :confirms, Integer
  key :difficulty, Float
  key :time, Time, :default => Time.now
  key :accounted, Boolean, :default => false
  key :confirmed, Boolean, :default => false
  timestamps!

  validates_uniqueness_of :hash

  def explorerHash
    if self.coin.blockExplorer.nil? or self.coin.blockExplorer.length == 0
        return "…#{self.hash[-15, 15]}"
    else
        url = self.coin.blockExplorer.gsub(/\#HASH/, self.hash)
        return "<a href='#{url}'>…#{self.hash[-15,15]}</a>"
    end
  end

end
