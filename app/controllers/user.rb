ManicminerPool::App.controllers :user do

    before do
        redirect('auth/login') unless current_account
    end

    before /wallet\/(add|edit)/ do
        @coins = Coin.all()
    end

    get :profile do
        checkAndCreateWallets(current_account)
        render 'user/profile'
    end

    # PROFILE OPERATIONS

    get 'password/edit' do
        render 'user/password-form'
    end

    post 'password/edit' do
        if current_account.has_password? params[:oldPassword]
            if params['password'] == params['password_confirmation']
                current_account.password = params['password']
                current_account.password_confirmation = params['password_confirmation']
                if current_account.save
                    flash[:success] = t 'forms.passwordEdit.ok'
                    redirect 'user/profile'
                else
                    flash[:error] = t 'forms.passwordEdit.errors.save'
                end
            else
                flash.now[:error] = t 'forms.passwordEdit.errors.match'
            end
        else
            flash.now[:error] = t 'forms.passwordEdit.errors.badpass'
        end

        render 'user/password-form'
    end

    # WORKER OPERATIONS

    get 'worker/add' do
        render 'user/worker-form'
    end

    post 'worker/add' do
        if current_account.workers.where(:name => params[:name]).count > 0
            flash.now[:error] = t 'mongo_mapper.errors.models.worker.attributes.name.taken'
            return render 'user/worker-form'
        end

        worker = Worker.create(
            :user => current_account,
            :name => params[:name],
            :difficulty => params[:difficulty]
        )
        if worker.save
            flash[:success] = t 'pages.worker.saved'

            redirect 'user/profile'
        else
            flash.now[:error] = t 'forms.worker.errors.save'
            errors = ""
            worker.errors.full_messages.each do |msg|
                errors += "#{msg}! "
            end
            flash.now[:warning] = errors

            render 'user/worker-form'
        end
    end

    get 'worker/delete/:id' do
        worker = current_account.workers.find(params[:id])
        if worker
            if isWorkerRunning worker
                flash[:error] = t 'pages.profile.nonedit'

                redirect 'user/profile'
            else
                worker.destroy
                flash[:success] = t 'pages.worker.deleted'

                redirect 'user/profile'
            end
        else
            halt 404, t('pages.worker.notfound')
        end
    end

    get 'worker/edit/:id' do
        @worker = current_account.workers.find(params[:id])
        if @worker
            if isWorkerRunning @worker
                flash[:error] = t 'pages.profile.nonedit'

                redirect 'user/profile'
            else
                render 'user/worker-edit'
            end
        else
            halt 404, "Worker not found for #{current_account.name}!"
        end
    end

    post 'worker/edit/:id' do
        worker = current_account.workers.find(params[:id])


        if worker
            worker.difficulty = params[:difficulty]

            if worker.save
                flash[:success] = t 'pages.worker.updated'

                redirect 'user/profile'
            else
                flash.now[:error] = t 'forms.worker.errors.save'
                flash.now[:warning] = (worker.errors.messages.map { |key, msg| "#{msg[0]} " }).to_s

                redirect 'user/profile'
            end
        else
            halt 404, "Worker not found for #{current_account.name}!"
        end
    end

    # WALLET OPERATIONS

    get 'wallet/edit/:id' do
        @wallet = current_account.wallets.find(params[:id])
        if @wallet
            render 'user/wallet-edit'
        else
            halt 404, "Wallet not found for #{current_account.name}!"
        end
    end

    post 'wallet/edit/:id' do
        wallet = current_account.wallets.find(params[:id])

        if wallet
            wallet.name    = params[:name]
            wallet.address = params[:address]
            wallet.payOn   = params[:payOn]

            if wallet.save
                flash[:success] = t 'pages.wallet.updated'

                redirect 'user/profile'
            else
                flash.now[:error] = t 'forms.wallet.errors.save'
                flash.now[:warning] = (wallet.errors.messages.map { |key, msg| "#{msg[0]} " }).to_s

                redirect 'user/profile'
            end
        else
            halt 404, "Wallet not found for #{current_account.name}!"
        end
    end

    get 'wallet/payout/:id' do
        @wallet = current_account.wallets.find(params[:id])
        if @wallet and @wallet.coin.active
            render 'user/payout-confirm'
        else
            halt 404, "Wallet not found for #{current_account.name}!"
        end
    end

    get 'wallet/payout-go/:id' do
        wallet = current_account.wallets.find(params[:id])
        @failed = false
        if wallet and wallet.coin.active
            coinClient = getCoinClient(wallet.coin)
            # Calculation
            begin
                txFee = wallet.coin.txFee
                restBalance = 0
                walletBalance = getWalletBalance(wallet)
                raise "Wallet offline" if walletBalance.is_a? String
                if walletBalance > 50000
                    restBalance = walletBalance - 50000
                    walletBalance = 50000
                end
                raise "Insufficient funds" if walletBalance - txFee < 0
            rescue Exception => e
                @failed = true
                @e = e
            end

            # Transfer funds
            if @failed == false
                begin
                    txId = coinClient.sendfrom(wallet.user.name, wallet.address, walletBalance - txFee)
                    @payoutTrans = Transaction.create(
                            :wallet => wallet,
                            :amount => -walletBalance,
                            :comments => 'USER PAYOUT',
                            :internalId => txId
                        )
                rescue Exception => e
                    @failed = true
                    @e = e
                end
            end

            # Transfer txFee
            if @failed == false
                begin
                    restFee = coinClient.getbalance(wallet.user.name)
                    if restFee > 0
                        # Take all as comission
                        coinClient.move(wallet.user.name, 'pooladmin', restFee)
                        # Revert > 50K
                        coinClient.move('pooladmin', wallet.user.name, restBalance) if restBalance > 0
                    end
                    @txFeeTrans = Transaction.create(
                        :wallet => wallet, :dtnAddress => 'TXFEE', :amount => -txFee, :fee => 0, :comments => 'FEE'
                    )
                rescue Exception => e
                    @failed = true
                    @e = e
                end
            end
        else
            halt 404, "Wallet not found for #{current_account.name}!"
        end

        if @failed == true
            flash[:error] = t('pages.wallet.transfer_fail')
            render 'user/payout-fail'
        else
            flash[:success] = t('pages.wallet.transfer_ok')
            render 'user/payout-ok'
        end
    end

    # TRADING
    get 'wallet/trade/:id' do
        wallet  = current_account.wallets.find(params[:id])
        if wallet and wallet.coin.active and wallet.coin.tradeOn
            funds        = getWalletBalance(wallet)
            btc_rate     = getCacheBtcLowestRate(wallet.coin)
            btc_total    = funds * btc_rate
            if btc_rate == 0
                flash.now[:info] = t 'pages.wallet.nochange'
                render 'user/profile'
            end
            if funds == 0
                flash.now[:info] = t 'pages.wallet.nofunds'
                render 'user/profile'
            end
            cr_operation = crOperation(wallet, funds, btc_rate, btc_total)
            render 'trade/show', :locals => {
                :wallet => wallet,
                :funds => funds,
                :btc_rate => btc_rate,
                :btc_total => btc_total,
                :cr_operation => cr_operation,
                :data_changed => false
            }
        else
            halt 404, "Wallet not found for #{current_account.name}!"
        end
    end

    get 'wallet/trade-confirm/:cr_operation/:id' do
        wallet  = current_account.wallets.find(params[:id])
        if wallet and wallet.coin.active
            funds        = getWalletBalance(wallet)
            btc_rate     = getCacheBtcLowestRate(wallet.coin)
            btc_total    = funds * btc_rate
            cr_operation = crOperation(wallet, funds, btc_rate, btc_total)
            if cr_operation != params[:cr_operation]
                flash.now[:info] = t 'pages.wallet.trade_changed'
                render 'trade/show', :locals => {
                    :wallet => wallet,
                    :funds => funds,
                    :btc_rate => btc_rate,
                    :btc_total => btc_total,
                    :cr_operation => cr_operation,
                    :data_changed => true
                }
            else
                coin          = wallet.coin
                coinClient    = getCoinClient(coin)
                btcClient     = getBtcCoinClient()
                btcUserWallet = getUserBtcWallet(current_account)
                halt(404, 'Coin not found!') unless coin
                halt(404, 'Coin Client problem!') unless coinClient
                halt(404, 'BTC Client problem!') unless btcClient
                halt(404, 'No user BTC wallet!!') unless btcUserWallet

                # Cash out wallet to btctrade account
                error = false
                errorText = ''
                begin
                    coinClient.move(wallet.user.name, 'btctrade', funds)
                    tx_a = Transaction.create(
                        :wallet => wallet,
                        :dtnAddress => "TO BTCTRADE OP:#{cr_operation}",
                        :amount => -funds, :fee => 0,
                        :comments => 'TRADE')
                rescue Exception => e
                    error     = true
                    errorText = "Cash transfer problem: #{e.message}"
                end

                # Pay the BTC change to user
                unless error
                    begin
                        btcClient.move('btctrade', wallet.user.name, btc_total)
                        tx_b = Transaction.create(
                            :wallet => btcUserWallet,
                            :dtnAddress => "FROM BTCTRADE OP:#{cr_operation}",
                            :amount => btc_total, :fee => 0,
                            :comments => "TRADE #{floatToHuman funds} #{wallet.coin.symbol}")
                    rescue Exception => e
                        error     = true
                        errorText = "BTC pay transfer problem: #{e.message}"
                    end
                end

                if error
                    render 'trade/error', :locals => {
                        :errorText    => errorText,
                        :wallet       => wallet,
                        :funds        => funds,
                        :btc_rate     => btc_rate,
                        :btc_total    => btc_total,
                        :cr_operation => cr_operation,
                        :data_changed => false
                    }
                else
                    flash[:success] = t 'pages.wallet.trade_ok'
                    render 'trade/ok', :locals => {
                        :wallet => wallet,
                        :funds => funds,
                        :btc_rate => btc_rate,
                        :btc_total => btc_total,
                        :cr_operation => cr_operation,
                        :data_changed => false,
                        :tx_a => tx_a,
                        :tx_b => tx_b
                    }
                end
            end
        else
            halt 404, "Wallet not found for #{current_account.name}!"
        end
    end

    # TRANSACTIONS
    get 'transactions/:symbol/:type' do
        symbol = params[:symbol]
        type = params[:type]
        coin = Coin.first(:symbol => symbol) unless symbol == 'all'

        if symbol == 'all' and type == 'all'
            transactions = current_account.transactions.sort(:created_at.desc)
        else
            if type != 'all'
                if type == 'in'
                    transactions = current_account.transactions.where(:amount.gt => 0)
                else
                    transactions = current_account.transactions.where(:amount.lt => 0)
                end
            end

            if symbol != 'all'
                if transactions
                    transactions = transactions.where(:coin_id => coin.id)
                else
                    transactions = current_account.transactions.where(:coin_id => coin.id)
                end
            end
        end

        @symbol = symbol
        @type   = type
        @transactions = transactions.sort(:created_at.desc).paginate(:page => params[:page], :per_page => 50)

        render 'user/transactions-list'
    end

    get :transactions  do
        @symbol = 'all'
        @type = 'all'
        @transactions = current_account.transactions.sort(:created_at.desc)
            .paginate(:page => params[:page], :per_page => 50)
        render 'user/transactions-list'
    end

    get 'profile/partials/:partial_name' do
        if params[:partial_name] =~ /^bitcoin\-wallet|wallets\-list|workers\-list$/
            render "partials/_#{params[:partial_name]}"
        else
            halt 404, 'What?'
        end
    end

end #Controller
