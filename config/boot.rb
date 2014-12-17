# Defines our constants
RACK_ENV = ENV['RACK_ENV'] ||= 'development' unless defined?(RACK_ENV)
PADRINO_ROOT = File.expand_path('../..', __FILE__) unless defined?(PADRINO_ROOT)

# Load our dependencies
require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, RACK_ENV)

Slim::Engine.default_options[:format] = :html5
Slim::Engine.default_options[:pretty] = true
Slim::Engine.default_options[:js_wrapper] = :both

##
# ## Enable devel logging
#
# Padrino::Logger::Config[:development][:log_level]  = :devel
# Padrino::Logger::Config[:development][:log_static] = true
#
# ## Configure your I18n
#
# I18n.default_locale = :en
#
# ## Configure your HTML5 data helpers
#
# Padrino::Helpers::TagHelpers::DATA_ATTRIBUTES.push(:dialog)
# text_field :foo, :dialog => true
# Generates: <input type="text" data-dialog="true" name="foo" />
#
# ## Add helpers to mailer
#
# Mail::Message.class_eval do
#   include Padrino::Helpers::NumberHelpers
#   include Padrino::Helpers::TranslationHelpers
# end

##
# Add your before (RE)load hooks here
#
Padrino.before_load do
  	require 'will_paginate'
  	require 'will_paginate/view_helpers/sinatra'
	# Padrino-contrib
  	include WillPaginate::Sinatra::Helpers
	I18n.default_locale = :en
	I18n.enforce_available_locales = false
end

##
# Add your after (RE)load hooks here
#
Padrino.after_load do
    logger.debug 'Creating database indexes'
    logger.debug 'Index Users'
    User.ensure_index(:name)
    logger.debug 'Index Workers'
    Worker.ensure_index(:name)
    logger.debug 'Index Wallets'
    Wallet.ensure_index(:name)
    Wallet.ensure_index(:coin_id)
    logger.debug 'Index Transactions'
    Transaction.ensure_index(:user_id)
    Transaction.ensure_index(:wallet_id)
    Transaction.ensure_index(:coin_id)
    logger.debug 'Index Coins'
    Coin.ensure_index(:symbol)
    logger.debug 'Index Blocks'
    Block.ensure_index(:hash)
    Block.ensure_index(:confirmed)
    Block.ensure_index(:accounted)
    Block.ensure_index(:height)
end

Padrino.load!
