ManicminerPool::App.controllers :auth do

    # Login form
    get :login do
        if current_account.nil?
            render 'auth/login'
        else
            redirect 'user/profile'
        end
    end

    # Do login
    post :login do
        if user = User.authenticate(params[:email], params[:password])
            if user.nologin
                flash[:error] = t 'auth.login.locked'
            else
                set_current_account(user)
                flash.now[:success] = t 'email.welcome'
                render 'user/profile'
            end
        else
            params[:email], params[:password] = h(params[:email]), h(params[:password])
            flash[:error] = t 'auth.login.error'
        end
        redirect 'auth/login'
    end

    # Logout
    get :logout do
        set_current_account(nil)
        flash[:info] = t 'auth.logout'
        redirect 'auth/login'
    end

    post '/pass/recover/edit' do
        if current_account
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
            halt 401, 'Unauthorized'
        end

        render 'auth/pass-recover-edit-form'
    end

    # Pass recover with token
    get :recover, :with => :token do
        if /SynHttpClient/.match(request.user_agent).nil?
            token = Token.first(:token => params[:token], :used => false, :kind => 'pass-recover')
            if token
                logger.debug "Token found: #{token.id}"
                token.used = true
                token.opened = "#{DateTime.now.to_s} by #{request.ip} with #{request.user_agent}"
                token.save
                set_current_account(token.user)
                flash.now[:info] = 'Ahora puedes cambiar tu contraseña'
                render 'auth/pass-recover-edit-form'
            else
                logger.debug "Token NOT found"
                render 'auth/recover-token-fail'
            end
        else
            "No SPAM here!"
        end
    end

    get '/pass/recover' do
        if current_account.nil?
            render 'auth/recover-form'
        else
            redirect 'user/profile'
        end
    end

    post '/pass/recover' do
        user = User.first(:email => params[:email])
        if user.nil?
            flash.now[:error] = t 'alerts.user.notfound'
            redirect 'auth/recover-form'
        else
            # Token
            token = Token.create(:user => user, :kind => 'pass-recover')
            logger.debug "New recover token: #{token.token}"
            # Mail
            deliver(:auth, :recover_email, token)
            flash[:success] = t 'alerts.recoverSend'

            redirect 'auth/login'
        end
    end

end
