ManicminerPool::App.controllers :contact do

  before do
    unless current_account
      flash[:error] = t 'pages.contact.unauthorized'
      redirect '/'
    end
  end

  get '/' do
    render 'home/contact-form'
  end

  post '/' do
    @user = current_account
    mail = params
    mail[:user] = current_account
    deliver(:contact, :contact_email, mail)
    flash[:success] = t 'pages.contact.sended'

    redirect '/'
  end

end
