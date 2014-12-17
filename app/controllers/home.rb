ManicminerPool::App.controllers :home, :map => '/' do

  get :index, :map => '/' do
  	redirect '/error/manicpay' if request.host =~ /^.*manicpay.*$/

    @tweetsBlock = cache('home-tweets', :expires => 600 ) do
		  @tweets = getLastTweets
		  partial 'partials/tweets'
    end

    render "home/index"
  end

  get 'error/:code' do
    if params[:code] =~ /^([0-9]*|manicpay)$/
  	 @title = "Error #{params[:code]}"
  	 @title = "Very soon" if params[:code] == "manicpay"
  	 render "errors/#{params[:code]}", :layout => :error
    else
      raise "Willy's wife is calling!"
    end
  end

  get 'raise/500' do
    halt 500, "Artificial error 500"
  end

  get 'raise/zero' do
    result = 5 / 0
  end
end
