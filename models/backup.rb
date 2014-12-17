class Backup
  include MongoMapper::Document

  # key <name>, <type>
  key :name, String
  key :path, String
  key :kind, String
  key :completed, Boolean, :default => false
  key :log, String
  key :size, Integer, :default => 0
  timestamps!
end
