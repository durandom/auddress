require 'test_helper'
require "#{File.dirname(__FILE__)}/../test_helper"


class JoinNowAndLoginOutTest < ActionController::IntegrationTest
  fixtures :users

  def dont_test_alpha_features
    gnu = new_session(:gnu)
    gnu.get imports_url
    gnu.post "/imports/vcard", {
      :upload => { 
        :file => fixture_file_upload("files/vCards.vcf", "text/x-vcard"),
        :file_temp => ''
      }
    } 
    
    
    gnu.logs_out
  end
  
  # taken from: Rails Cookbook, 2007, O'Reilly
  #Recipe 7.12. Testing Across Controllers with Integration Tests
  # FIXME: move this to test_helper ?
  module LoginLogout
    def log_in_user(user)
      post "/session", :login => users(user).login, 
        :password => "test"
      assert_response :redirect
      follow_redirect!
      assert_response :success
    end     
        
    def logs_out
      post "/logout"
      assert_response :redirect
      # redirects to /
      follow_redirect!
      # redirects to session/new
      follow_redirect!
      assert_response :success
    end     
  end

  def new_session(user = nil)
    open_session do |sess|
      sess.extend(LoginLogout)
      sess.log_in_user(user) if user
    end
  end

end
