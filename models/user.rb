class User < Account
  include MongoMapper::Document
  safe

  # key <name>, <type>
  key :emailConfirm, Boolean, :default  => false
  key :active,       Boolean, :default  => false
  key :seen_at,      Time,    :default  => Time.now
  key :nologin,      Boolean, :defualt  => false

  timestamps!

  many :workers
  many :wallets
  many :tokens
  many :transactions

  validates_uniqueness_of :name
  validates_uniqueness_of :email
  validates_format_of     :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

  before_validation :complete

  public
    def getName
      self.name.titleize
    end

    def isActivated
      self.emailConfirm and self.active
    end

    def isAdmin
      return true if self.role == 'admin'
      return false
    end

    def isForumAdmin
      return true if self.role == 'admin'
      return true if self.role == 'forum-admin'
      return false
    end

  private
    def complete
      self.name = self.name.downcase
    end

end
