ManicminerPool::App.controllers :register do

  get '/user' do
    render 'register/form'
  end

  post '/user' do
    logger.debug "[REGISTER:USER] Data recv: #{params.to_s}"

    userData = params
    userData[:role] = 'user'
    userData.delete(:authenticity_token)
    userData.delete(:format)
    user = User.create(userData)

    if user.save
      logger.debug "[REGISTER:USER] User saved: #{user.name} -> #{user.id}"
      set_current_account(user)

      token = Token.create(:user => user, :kind => 'email-confirm')
      deliver(:auth, :registration_email, token)

      redirect 'register/ok'
    else
      logger.debug "[REGISTER:USER] Cannot save user: #{user.errors.inspect}"
      flash.now[:error] = t 'forms.registration.errors.save'
      errorText = ""
      user.errors.messages.each do |field, text|
        errorText += "#{text[0].to_s} "
      end
      flash.now[:warning] = errorText

      render 'register/form'
    end
  end

  get '/ok' do
    render 'register/ok'
  end

  get '/test/mail' do
    if Padrino.env == :development
      token = Token.first()
      if token
        deliver(:auth, :registration_email, token)
        render "mailers/registration_email-#{I18n.locale}",
          :layout => 'mailers/layouts/mail', :locals => {:token => token}
      else
        'No tokens!!!'
      end
    else
      halt 404, '404: Not found!'
    end
  end

  get :confirm, :with => :token do
    if /SynHttpClient/.match(request.user_agent).nil?
      token = Token.first(:token => params[:token], :used => false, :kind => 'email-confirm')
      if token
        logger.debug "Token found: #{token.id}"
        user = token.user
        if user.emailConfirm == false
          logger.debug "Activating user: #{user.email}"
          user.emailConfirm = true
          user.active = true
          if user.save
            set_current_account(user)
            logger.debug "Set flash: #{t 'alerts.email-confirm.ok'}"
            flash[:success] = t 'alerts.email-confirm.ok'
            token.used = true
            token.opened = "#{DateTime.now.to_s} by #{request.ip} with #{request.user_agent}"
            token.save!

            redirect 'user/profile'
          else
            @message = 'Cannot save user!'
            halt 500, 'Cannot save user!'
          end
        else
          logger.debug "User already activated: #{user.email}"
          @message = t('alerts.email-confirm.already')
          halt 404, t('alerts.email-confirm.already')
        end
      else
        logger.debug "Token not found: #{params[:token]}"
        @message =  t('alerts.email-confirm.notfound')
        halt 404, t('alerts.email-confirm.notfound')
      end
    else
      "No SPAM here!"
    end
  end

  get '/activation/resend/:id' do
    user = User.first(:id => params[:id])
    halt(404, 'User not found!') unless user
    halt(404, 'Already activated') if user.emailConfirm
    token = Token.create(:user => user, :kind => 'email-confirm')
    raise(500, 'Cannot create token') unless token
    deliver(:auth, :registration_email, token)
    render 'register/activation-resend', :locals => {:user => user}
  end

end
