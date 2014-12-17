class HourlyStats
  include MongoMapper::Document

  # key <name>, <type>
  key :hour,       Integer
  key :maxUsers,   Integer
  key :maxWorkers, Integer
  key :maxSpeed,   Float
  key :minUsers,   Integer
  key :minWorkers, Integer
  key :minSpeed,   Float
  key :avgUsers,   Integer
  key :avgWorkers, Integer
  key :avgSpeed,   Float
  timestamps!
end
