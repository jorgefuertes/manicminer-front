class Worker
  include MongoMapper::Document

  belongs_to :user

  # key <name>, <type>
  key :name, String, :required => true
  key :difficulty, Integer, :default => 10
  key :seenAt, Time, :default => Time.now

  timestamps!

  validate :custom_validation
  before_validation :complete

  public
    def active
      return true if seenAt > Time.now - 300
      return false
    end

  private
    def custom_validation
      errors.add(:difficulty, I18n::t('mongo_mapper.errors.models.worker.attributes.difficulty.min')) if self.difficulty < 4
      errors.add(:difficulty, I18n::t('mongo_mapper.errors.models.worker.attributes.difficulty.max')) if self.difficulty > 5000
    end

    def complete
      self.name = self.name.downcase
    end

end
