require File.dirname(__FILE__) + '/../test_helper'

class LinkRequestsControllerTest < ActionController::TestCase
  def setup
    # runs before every test
    login
  end
  
  def test_should_create_link_request
    post :create, {:person_id => people(:reese).id}
    assert_not_nil LinkRequest.find_by_person_id(people(:reese).id)
  end
  
end
