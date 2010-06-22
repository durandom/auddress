require "#{File.dirname(__FILE__)}/../test_helper"

class LinkRequestWithInvitationTest < ActionController::IntegrationTest
 fixtures :users

  def test_creates_link_request_follows_invitation_and_signsup_and_accepts_link
    urandom = new_session(:urandom)
    # request link for reese
    urandom.post link_requests_url, {:person_id => people(:reese).id}
    # get that link request
    lr = LinkRequest.find_by_person_id(people(:reese).id)
    assert_not_nil lr
    # invitation should have been send
    assert_not_nil lr.invitation
    # create new user with the invitation token
    reese = new_session
    # follow the link in the email
    reese.get signup_url, {:token => lr.invitation.token}
    reese.assert_response :success
    reese.post users_url, { :user => {
        :login => 'reese',
        :password => 'test',
        :password_confirmation => 'test'}
    }
    # get the newly created user
    reese_user = User.find_by_login('reese')
    # refresh invitation
    lr.reload
    # invitation should be invalid
    assert_empty lr.invitation.token
    # new reese user should be bound to invitation
    assert_equal reese_user, lr.invitation.invited_user
    # link request should also be bound to new user
    assert_equal reese_user, lr.requested_user

    reese.post url_for(:action => 'accept', :controller => 'link_requests'), {:id => lr.id}
    reese.assert_response :success
    # link request should be accepted
    lr.reload
    assert lr.accepted?
    
    
    reese.logs_out
    urandom.logs_out
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
