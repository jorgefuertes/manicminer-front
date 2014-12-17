ManicminerPool::App.controllers :userapi do

  before do
    unless current_account
        halt 401, "Unauthorized: Before controller."
    end
  end


  # JSON Updates, deprecated:
  get '/workers/speed', :provides => :json do
    data = {}
    current_account.workers.each do |worker|
        data[:"#{worker.id}"] = {
            :active => boolToHumanLabel(isWorkerRunning(worker)),
            :speed => hashesToHuman(getWorkerSpeed(worker)),
            :dead => hashesToHuman(getWorkerDeadSpeed(worker))
        }
    end

    return data.to_json
  end

  get '/wallets/update', :provides => :json do
    wallets = []
    btc_total_avg = 0
    btc_total_lowest = 0
    current_account.wallets.each do |wallet|
      if wallet.coin.active
        balance           = getBalance(wallet)
        btc_avg           = btcValue(balance, wallet.coin.symbol).to_f
        btc_lowest        = btcMinValue(balance, wallet.coin.symbol).to_f
        btc_value_html    =
          "<span class=\"small gray\">#{t 'titles.ticker.min'}</span>"\
          "<span class=\"medium\">#{floatToHuman btc_lowest}</span>"\
          "<br />"\
          "<span class=\"small gray\">#{t 'titles.ticker.avg'}</span>"\
          "<span class=\"medium\">#{floatToHuman btc_avg}</span>"
        btc_total_avg    += btc_avg
        btc_total_lowest += btc_lowest
        if wallet.coin.symbol != 'BTC'
          wallets << {
            :id      => wallet.id,
            :address => wallet.address,
            :amount  => floatToHuman(balance),
            :txfee   => floatToHuman(wallet.coin.txFee),
            :btc     => btc_value_html
          }
        else
          wallets << {
            :id      => wallet.id,
            :address => wallet.address,
            :amount  => floatToHuman(balance),
            :txfee   => floatToHuman(wallet.coin.txFee)
          }
        end
      end
    end

    btc_total_html =
        "<span class=\"small\">#{t 'pages.wallet.btc_total'}:</span> "\
        "<span class=\"small gray\">#{t 'titles.ticker.min'}</span>#{floatToHuman btc_total_lowest}"\
        "/"\
        "<span class=\"small gray\">#{t 'titles.ticker.avg'}</span>#{floatToHuman btc_total_avg}"

    return {
        :wallets => wallets,
        :btc_total => btc_total_html
      }.to_json
  end

  # HTML partials:

  get '/workers/list', :provides => :html do
    partial 'partials/workers-list', :locals => {:user => current_account}
  end

  get '/wallets/list', :provides => :html do
    partial 'partials/wallets-list', :locals => {:user => current_account}
  end

  get '/wallets/bitcoin', :provides => :html do
    partial 'partials/bitcoin-wallet', :locals => {:user => current_account}
  end

  get '/transactions/list', :provides => :html do
    partial 'partials/user-transactions', :locals => {:user => current_account}
  end

end
