ManicminerPool::App.controllers :stats do

  get 'general' do
    render 'stats/general'
  end

  # blocks
  get 'blocks/:symbol' do
    @coin = Coin.first(:symbol => params[:symbol])
    if @coin
      @blocks = Block.where(:coin_id => @coin.id)
        .sort(:time.desc).paginate(:page => params[:page], :per_page => 50)
      render 'stats/blocks'
    else
      halt 404, t('pages.transactions.coinNotFound')
    end
  end

  get :blocks  do
    @coin = nil
    @blocks = Block.sort(:created_at.desc)
      .paginate(:page => params[:page], :per_page => 50)
    render 'stats/blocks'
  end

  get 'test' do
    result = {}
    Coin.where(:active => true, :mainChain => true).each do |coin|
      if Padrino.env == :development
        host = 'dev.manicminer.in'
        port = coin.poolPort
      else
        host = coin.poolHost
        port = coin.poolPort
      end

      begin
        response = HTTParty.get("http://#{host}:#{port}/local_stats")
        parsed = JSON.parse response.body
        parsed['ok'] = true
      rescue Exception => e
        parsed = {'ok' => false, 'message' => e.message}
      end

      result[coin.symbol] = parsed
    end

    output = "<h1>Stats:</h1><ul>"
    result.each do |key, value|
      output += "<li><strong>#{key}</strong>:<ul>"
      value.each do |subkey, subvalue|
        output += "<li><strong>#{subkey}</strong>: #{subvalue.inspect}</li>"
      end
      output += "</ul>"
    end
    output += "</ul>"

    output
  end

  get 'power-table' do
    render 'stats/power-table'
  end

  get 'changes-table' do
    render 'stats/changes-table'
  end

  get 'charts/speed' do
    render 'stats/speed-chart'
  end

end
