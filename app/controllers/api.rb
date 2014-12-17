ManicminerPool::App.controllers :api do

  before do
    # Change @api_key value to any secret string
    @api_key = ''
  end

  # Check worker
  get 'check/worker/:username/:worker', :provides => :json do

    user = User.first(:name => params[:username].downcase)
    halt(404, {:ok => false, :error => 'User unknown'}.to_json) if user.nil?
    halt(403, 'User not activated') unless user.isActivated

    worker = user.workers.first(:name => params[:worker].downcase)
    halt(404, {:ok => false, :error => 'Worker not found'}.to_json) unless worker
    worker.seenAt = Time.now
    worker.save

    return {:ok => true, :id => worker.id, :difficulty => worker.difficulty}.to_json
  end

  # Insert submmited work (now its a bypass)
  get 'submit/:target/:username/:worker/:coinsymbol/:workid', :provides => :json do
    {:ok => true, :id => 'bypassed'}.to_json
  end

  # Insert completed result
  get 'result/:target/:timestamp/:username/:worker/:coinsymbol/:workid/:valid', :provides => :json do
    {:ok => true, :id => 'bypassed'}.to_json
  end

  # Plain mailing list
  get 'mailing-list/:secret/mails', :provides => :txt do
    return 403 if @api_key == '' or @api_key != params[:secret]
    output = ""
    User.where(:active => true, :emailConfirm => true).each do |user|
      output += "#{user.email.downcase}\n"
    end

    return output
  end

  # Complete mailing list json
  # APIKEY: Any secret string
  get 'mailing-list/:secret/mails', :provides => :json do
    return 403 if @api_key == '' or @api_key != params[:secret]
    users = []
    User.where(:active => true, :emailConfirm => true).each do |user|
      users += [:name => user.name, :email => user.email.downcase]
    end

    return users.to_json
  end

end
