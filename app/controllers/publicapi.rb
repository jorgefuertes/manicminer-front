ManicminerPool::App.controllers :publicapi do

  get 'blocks/last', :provides => :json do
  	data = {}
  	counter = 0
    Block.where(:sort => :time.desc, :limit => 25).each do |block|
	 	  data[counter] = {
  			:id => block.id,
  			:time => block.time.strftime("%H:%M:%S"),
  			:hash => block.hash,
  			:coin => Coin.find(block.coin_id).symbol,
  			:confirms => block.confirms,
  			:amount => block.amount
  		}
		  counter += 1
    end

    return data.to_json
  end

  get 'blocks/last/since/:id', :provides => :json do
    data = {}
    counter = 0
    firstBlock = Block.find(params[:id])
    since = firstBlock.time
    logger.debug "Since: #{firstBlock.id} --> #{since}"
    Block.where(:time.gt => since).sort(:time.asc).limit(25).each do |block|
      data[counter] = {
        :id => block.id,
        :time => block.time.strftime("%H:%M:%S"),
        :hash => block.hash,
        :coin => Coin.find(block.coin_id).symbol,
        :confirms => block.confirms,
        :amount => block.amount
      }
      counter += 1
    end

    return data.to_json
  end

end
