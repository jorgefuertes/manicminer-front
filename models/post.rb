class Post
  include MongoMapper::Document

  belongs_to :user

  # key <name>, <type>
  key :lang, String
  key :slug, String
  key :title, String
  key :body, String
  timestamps!

  validates_uniqueness_of :slug

end
