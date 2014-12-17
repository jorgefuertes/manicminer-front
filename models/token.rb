class Token
  include MongoMapper::Document
  safe

  belongs_to :user

  # property <name>, <type>
  key :kind,    String,   :default  => 'other'
  key :token,   String,   :required => true, :default => 'none'
  key :expires, DateTime, :required => true, :default => DateTime.now
  key :used,    Boolean,  :default  => false
  key :opened,  String,   :required => false

  before_create :set_token

  timestamps!

  private
    def set_token
      @token = SecureRandom.hex 16
      @expires = DateTime.now + 2
    end

end
