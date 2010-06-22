# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test
config.action_mailer.default_url_options = { :host => "localhost:3000" }

# remove the ?NNNN from urls for CSSEDIT
# http://www.artofmission.com/articles/2007/6/19/cssedit-with-rails
ENV["RAILS_ASSET_ID"] = ""

# We want to modifiy this plugin, make rails detect changes
ActiveSupport::Dependencies.load_once_paths.delete(RAILS_ROOT + '/vendor/plugins/contacts/lib')