MongoMapper.connection = Mongo::Connection.new('localhost', nil, :logger => logger,
	:pool_size => 32, :pool_timeout => 4)

case Padrino.env
  when :development then MongoMapper.database = 'manicminer_pool_development'
  when :production  then MongoMapper.database = 'manicminer_pool_production'
  when :test        then MongoMapper.database = 'manicminer_pool_test'
end
