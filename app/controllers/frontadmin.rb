ManicminerPool::App.controllers :frontadmin do

  before do
    unless current_account and current_account.role == 'admin'
      halt 401, "Unauthorized."
    end
  end

  get '/view/user/:id' do
    if @user = User.find(params[:id])
      render 'frontadmin/user-view'
    else
      halt 404, 'User not found'
    end
  end

  get '/users' do
    @users = User.sort(:name.asc).paginate(:page => params[:page], :per_page => 250)

    render 'frontadmin/users'
  end

  get '/news' do
    render 'frontadmin/news-index'
  end

  get '/news/post/add' do
    render 'frontadmin/news-add'
  end

  post '/users/search' do
    @users = User.where(:name => /#{params[:search]}/i).sort(:name.asc).paginate(:page => params[:page], :per_page => 250)

    render 'frontadmin/users'
  end

  get '/news' do
    render 'frontadmin/news-index'
  end

  get '/news/post/add' do
    render 'frontadmin/news-add'
  end

  post '/news/post/add' do
    post = Post.create(
        :user => current_account,
        :locale => params[:locale],
        :title => params[:title],
        :slug => params[:slug],
        :body => params[:body]
      )
    if post.save
      flash[:success] = t 'forms.post.saved'
      sendTweet("#{post.title}: http://#{post.locale}.manicminer.in/news/#{post.slug}")
      redirect '/frontadmin/news'
    else
      flash.now[:error] = t 'forms.post.errors.save'
      errors = ""
      post.errors.full_messages.each do |msg|
        errors << "#{msg}! "
      end
      flash.now[:warning] = errors

      render 'frontadmin/news-add'
    end
  end

  get '/news/post/delete/:id' do
    post = Post.first(:id => params[:id])
    if post
      post.destroy
      redirect 'frontadmin/news'
    else
      halt 404, 'Post not found'
    end
  end

  get '/news/post/edit/:id' do
    @post = Post.first(:id => params[:id])
    if @post
      render 'frontadmin/news-edit'
    else
      halt 404, 'Post not found'
    end
  end

  post '/news/post/edit/:id' do
    post = Post.first(:id => params[:id])
    if post
      post.locale = params[:locale]
      post.title  = params[:title]
      post.slug   = params[:slug]
      post.body   = params[:body]
      if post.save
        flash[:success] = t 'forms.post.saved'
      else
        flash[:error] = t 'forms.post.errors.save'
        errors = ""
        post.errors.full_messages.each do |msg|
          errors << "#{msg}! "
        end
        flash[:warning] = errors
      end
    else
      halt 404, 'Post not found'
    end
    redirect '/frontadmin/news'
  end

  get '/password/edit/:id' do
    @user = User.first(:id => params[:id])
    render 'frontadmin/password-edit'
  end

  post '/password/edit/:id' do
    user = User.first(:id => params[:id])
    if user
      if params['password'] == params['password_confirmation']
        user.password = params['password']
        user.password_confirmation = params['password_confirmation']
        if user.save
          flash[:success] = t 'forms.passwordEdit.ok'
          redirect "frontadmin/view/user/#{user.id}"
        else
          flash[:error] = t 'forms.passwordEdit.errors.save'
        end
      else
        flash.now[:error] = t 'forms.passwordEdit.errors.match'
      end
    else
      flash.now[:error] = t 'forms.passwordEdit.errors.badpass'
    end

    render 'frontadmin/password-edit'
  end

  # --- COINS ---
  get '/coins' do
    render 'frontadmin/coin-list'
  end

  get '/coins/edit/:id' do
    @coin = Coin.find(params[:id])
    if @coin
      render 'frontadmin/coin-edit'
    else
      halt 404, 'Coin not found'
    end
  end

  post '/coins/edit/:id' do
    coin = Coin.find(params[:id])
    if coin
      coin.name = params[:name]
      coin.symbol = params[:symbol]
      coin.colorClass = params[:colorClass]
      coin.mainChain = params[:mainChain].eql? 'on'
      coin.active = params[:active].eql? 'on'
      coin.powerOn = params[:powerOn].eql? 'on'
      coin.getBlocks = params[:getBlocks].eql? 'on'
      coin.autoShare = params[:autoShare].eql? 'on'
      coin.integerOnly = params[:integerOnly].eql? 'on'
      coin.tradeOn = params[:tradeOn].eql? 'on'
      coin.txFee = params[:txFee].to_f
      coin.blockValue = params[:blockValue].to_f
      coin.confirms = params[:confirms]
      coin.poolHost = params[:poolHost]
      coin.poolPort = params[:poolPort]
      coin.port = params[:port]
      coin.rpcUser = params[:rpcUser]
      coin.rpcPass = params[:rpcPass]
      coin.rpcHost = params[:rpcHost]
      coin.rpcPort = params[:rpcPort]
      coin.blockExplorer = params[:blockExplorer]
      coin.url = params[:url]
      coin.urlWallets = params[:urlWallets]

      if coin.save
        flash[:success] = 'Coin saved successful!'
        redirect 'frontadmin/coins'
      else
        flash[:error] = 'Cannot save coin!'
        @coin = coin
        render 'frontadmin/coin-edit'
      end
    else
      halt 404, 'Coin not found'
    end
  end

  get '/coins/add' do
    @coin = Coin.new
    render 'frontadmin/coin-add'
  end

  post '/coins/add' do
    coin = Coin.new
    coin.name = params[:name]
    coin.symbol = params[:symbol]
    coin.colorClass = params[:colorClass]
    coin.mainChain = params[:mainChain].eql? 'on'
    coin.active = params[:active].eql? 'on'
    coin.powerOn = params[:powerOn].eql? 'on'
    coin.getBlocks = params[:getBlocks].eql? 'on'
    coin.autoShare = params[:autoShare].eql? 'on'
    coin.integerOnly = params[:integerOnly].eql? 'on'
    coin.tradeOn = params[:tradeOn].eql? 'on'
    coin.txFee = params[:txFee].to_f
    coin.blockValue = params[:blockValue].to_f
    coin.confirms = params[:confirms]
    coin.poolHost = params[:poolHost]
    coin.poolPort = params[:poolPort]
    coin.port = params[:port]
    coin.rpcUser = params[:rpcUser]
    coin.rpcPass = params[:rpcPass]
    coin.rpcHost = params[:rpcHost]
    coin.rpcPort = params[:rpcPort]
    coin.blockExplorer = params[:blockExplorer]
    coin.url = params[:url]
    coin.urlWallets = params[:urlWallets]

    if coin.save
      flash[:success] = 'Coin saved successful!'
      redirect 'frontadmin/coins'
    else
      flash[:error] = 'Cannot save coin!'
      @coin = coin
      render 'frontadmin/coin-edit'
    end
  end

  get '/backups/show/:id' do
    bk = Backup.first(:id => params[:id])
    if bk
      render 'frontadmin/backup-show', :locals => {:bk => bk}
    else
      halt 404, 'Backup not found'
    end
  end

  get '/backups' do
    render 'frontadmin/backup-list'
  end
end
