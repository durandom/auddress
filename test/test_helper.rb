ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'test/zentest_assertions'

class ActiveSupport::TestCase
  # RoleRequirementTestHelper must be included to test RoleRequirement
  include RoleRequirementTestHelper

  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  
  # taken from
  # http://alexbrie.net/1526/functional-tests-with-login-in-rails/
  fixtures :users
  def login(login='urandom', password='test')
    old_controller = @controller
    @controller = SessionsController.new
    post :create, :login => login, :password => password
    assert_response :redirect
    assert_not_nil session[:user_id]
    @controller = old_controller
  end

#  def populate_ldap_tree
#
#  end
#
#  def reset_ldap(login='urandom')
#    if UserLdap.exists?(login)
#      ldap = UserLdap.find(login)
#      ldap.destroy
#    end
#  end
  
  def logger
    RAILS_DEFAULT_LOGGER
  end
end
