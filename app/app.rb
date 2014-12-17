module ManicminerPool
  class App < Padrino::Application
    register WillPaginate::Sinatra
    register SassInitializer
    register Padrino::Rendering
    register Padrino::Mailer
    register Padrino::Helpers

    disable :raise_errors if Padrino.env == :production
    disable :show_exceptions if Padrino.env == :production
    #disable :raise_errors
    #disable :show_exceptions

    enable :sessions
    layout :main

    register Padrino::Cache
    enable :caching
    set :cache, Padrino::Cache.new(:Redis)

    register Padrino::Admin::AccessControl
    enable :authentication
    enable :store_location
    set    :login_page, '/auth/login'

    access_control.roles_for :any do |role|
        role.protect '/user'
        role.protect '/userapi'
        role.protect '/frontadmin'
    end

    access_control.roles_for :admin do |role|
        role.protect '/frontadmin'
    end

    # HERE!!!
    # MAIL CONFIGURATION
    set :mailer_defaults, {
        :from => 'no-reply@yourdomain.com',
        :content_type => 'html'
    }

    set :delivery_method, :smtp => {
        :address              => 'smtp.yourmailserver.com',
        :port                 => 587,
        :user_name            => 'webmaster@yourdomain.com',
        :password             => 'yourpassword',
        :authentication       => :plain,
        :enable_starttls_auto => true
    }

    ##
    # Caching support.
    #
    # register Padrino::Cache
    # enable :caching
    #
    # You can customize caching store engines:
    #
    # set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
    # set :cache, Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1))
    # set :cache, Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
    # set :cache, Padrino::Cache::Store::Memory.new(50)
    # set :cache, Padrino::Cache::Store::File.new(Padrino.root('tmp', app_name.to_s, 'cache')) # default choice
    #

    ##
    # Application configuration options.
    #
    # set :raise_errors, true       # Raise exceptions (will stop application) (default for test)
    # set :dump_errors, true        # Exception backtraces are written to STDERR (default for production/development)
    # set :show_exceptions, true    # Shows a stack trace in browser (default for development)
    # set :logging, true            # Logging in STDOUT for development and file for production (default only for development)
    # set :public_folder, 'foo/bar' # Location for static assets (default root/public)
    # set :reload, false            # Reload application files (default in development)
    # set :default_builder, 'foo'   # Set a custom form builder (default 'StandardFormBuilder')
    # set :locale_path, 'bar'       # Set path for I18n translations (default your_apps_root_path/locale)
    # disable :sessions             # Disabled sessions by default (enable if needed)
    # disable :flash                # Disables sinatra-flash (enabled by default if Sinatra::Flash is defined)
    # layout  :my_layout            # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
    #

    ##
    # You can configure for a specified environment like:
    #
    #   configure :development do
    #     set :foo, :bar
    #     disable :asset_stamp # no asset timestamping for dev
    #   end
    #

    ##
    # You can manage errors like:
    #
    #   error 404 do
    #     render 'errors/404'
    #   end
    #
    #   error 505 do
    #     render 'errors/505'
    #   end
    #

    error(404) do
        @title = "Error 404"
        render('errors/404', :layout => :error, :locals => {:message => 'Not found!'})
    end

    error(500) do |e = 'Unknown error'|
        @title   = "Error 500"
        username = 'Unknown'
        username = current_account.name unless current_account.nil?
        userid   = 'unknown'
        userid   = current_account.id unless current_account.nil?
        if request.env['sinatra.error']
            message = request.env['sinatra.error'].message
            trace   = request.env['sinatra.error'].backtrace
        else
            message = 'No exception'
            trace   = 'No trace'
        end

        report = {
            :username => username,
            :userid   => userid,
            :userinfo => "http://manicminer.in/frontadmin/view/user/#{userid}",
            :userip   => request.ip,
            :host     => "#{request.host}:#{request.port}",
            :url      => request.url,
            :string   => request.query_string,
            :method   => request.request_method,
            :referer  => request.referer,
            :locale   => I18n.locale,
            :message  => message,
            :trace    => trace,
            :date     => Time.now.to_s
        }
        deliver(:error, :error_email, report)
        render('errors/500', :layout => :error, :locals => {:message => message})
    end

    error(505) { @title = "Error 505"; render('errors/500', :layout => :error) }

    before do
        I18n.reload!  if Padrino.env == :development
        setLocale
    end

    configure :development do
        set :host, "http://localhost:3000"
        use BetterErrors::Middleware
        BetterErrors.application_root = PADRINO_ROOT
        set :protect_from_csrf, except: %r{/__better_errors/\d+/\w+\z}
    end

    configure :production do
        set :host, "http://manicminer.in"
    end

    def self.abs_url_for(*args)
        return settings.host + url(*args)
    end

  end
end
