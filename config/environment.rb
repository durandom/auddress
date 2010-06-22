# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
#RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_auddress_session',
    :secret      => '9ff895bb3a42f920ea5534a59ec6fdc789cf05ee3a2498a2346eed80fe5f087b212af7f75ed58cfa83ce8e9d5c6e3790dfd8245296661ef08c38ef0ee4138b35'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store
  # FIXME: we should use the cookie store, but somehow we store more than 4kb?
  
  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc

  # Install these gems using rake gems:install (use sudo if necessary)
  #config.gem "gettext", :lib => "gettext/rails"
  config.gem 'mislav-will_paginate', :version => '>= 2.2.3',
    :lib => 'will_paginate', :source => 'http://gems.github.com'
  config.gem 'vpim', :version => '~> 0.658'
  config.gem 'open4'
  config.gem 'diff-lcs', :version => '~> 1.1', :lib => 'diff/lcs'
  config.gem 'grit'
  config.gem 'hpricot'

  config.action_mailer.default_url_options = { :host => "auddress.com" }
end

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
	:date => "%Y-%m-%d",
	:presentable_datetime => "%a %b %d, %Y %H:%M",
	:presentable_date => "%a %b %d, %Y"
)

ActionMailer::Base.delivery_method = :sendmail
ActionMailer::Base.raise_delivery_errors = true

# Requires, which we need for sure
#require 'digest/md5'
#require 'vpim/vcard'
