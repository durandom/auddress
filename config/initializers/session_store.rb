# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rails_skel_session',
  :secret      => 'db62894751e7a423f6b5742527ae6b36d716814caa2e5497c8655b79824a355199639b65d365fa6173c2a7f36d026559268c8c7d0d416e56922532aba34c213e'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
#ActionController::Base.session_store = :active_record_store
ActionController::Base.session_store = :cookie_store
