require File.dirname(__FILE__) + '/../test_helper'

class LinkRequestTest < ActiveSupport::TestCase
  fixtures :users, :people

  def test_finds_correct_requested_person
    lr = LinkRequest.new
    # urandom requests a link
    lr.user = users(:urandom)
    # from his book he selects zosel
    lr.person = people(:urandom_zosel)
    lr.save
    assert_equal lr.requested_user.login, 'gando'
  end
  
  def test_user_not_allowed_to_request_for_foreign_person
    assert_raise Exception do
      lr = LinkRequest.new
      lr.user = users(:urandom)
      # zosel is not owned by urandom
      lr.person = people(:zosel)
      lr.save
    end
  end
  
  def test_creates_invitation_on_person_not_in_system
    lr = LinkRequest.new
    lr.user = users(:urandom)
    # reese has no account
    lr.person = people(:reese)
    lr.save
    assert_not_nil Invitation.find_by_person_id(people(:reese).id)
  end
end
