ManicminerPool::Admin.controllers :wallets do
  get :index do
    @title = "Wallets"
    @wallets = Wallet.sort(:name.asc).paginate(:page => params[:page], :per_page => 100)
    render 'wallets/index'
  end

  get :new do
    @title = pat(:new_title, :model => 'wallet')
    @wallet = Wallet.new
    render 'wallets/new'
  end

  post :create do
    @wallet = Wallet.new(params[:wallet])
    if @wallet.save
      @title = pat(:create_title, :model => "wallet #{@wallet.id}")
      flash[:success] = pat(:create_success, :model => 'Wallet')
      params[:save_and_continue] ? redirect(url(:wallets, :index)) : redirect(url(:wallets, :edit, :id => @wallet.id))
    else
      @title = pat(:create_title, :model => 'wallet')
      flash.now[:error] = pat(:create_error, :model => 'wallet')
      render 'wallets/new'
    end
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "wallet #{params[:id]}")
    @wallet = Wallet.find(params[:id])
    if @wallet
      render 'wallets/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'wallet', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "wallet #{params[:id]}")
    @wallet = Wallet.find(params[:id])
    if @wallet
      if @wallet.update_attributes(params[:wallet])
        flash[:success] = pat(:update_success, :model => 'Wallet', :id =>  "#{params[:id]}")
        params[:save_and_continue] ?
          redirect(url(:wallets, :index)) :
          redirect(url(:wallets, :edit, :id => @wallet.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'wallet')
        render 'wallets/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'wallet', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy, :with => :id do
    @title = "Wallets"
    wallet = Wallet.find(params[:id])
    if wallet
      if wallet.destroy
        flash[:success] = pat(:delete_success, :model => 'Wallet', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'wallet')
      end
      redirect url(:wallets, :index)
    else
      flash[:warning] = pat(:delete_warning, :model => 'wallet', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy_many do
    @title = "Wallets"
    unless params[:wallet_ids]
      flash[:error] = pat(:destroy_many_error, :model => 'wallet')
      redirect(url(:wallets, :index))
    end
    ids = params[:wallet_ids].split(',').map(&:strip)
    wallets = Wallet.find(ids)

    if wallets.each(&:destroy)

      flash[:success] = pat(:destroy_many_success, :model => 'Wallets', :ids => "#{ids.to_sentence}")
    end
    redirect url(:wallets, :index)
  end
end
