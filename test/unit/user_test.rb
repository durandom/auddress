require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  fixtures :users


  def test_should_create_user
    assert_difference 'User.count' do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_login
    assert_no_difference 'User.count' do
      u = create_user(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_require_password
    assert_no_difference 'User.count' do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference 'User.count' do
      u = create_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_reset_password
    users(:urandom).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:urandom), User.authenticate('urandom', 'new password')
  end

  def test_should_not_rehash_password
    users(:urandom).update_attributes(:login => 'urandom2')
    users(:urandom).save
    assert_equal users(:urandom), User.authenticate('urandom2', 'test')
  end

  def test_should_authenticate_user
    assert_equal users(:urandom), User.authenticate('urandom', 'test')
  end

  def test_should_set_remember_token
    users(:urandom).remember_me
    assert_not_nil users(:urandom).remember_token
    assert_not_nil users(:urandom).remember_token_expires_at
  end

  def test_should_unset_remember_token
    users(:urandom).remember_me
    assert_not_nil users(:urandom).remember_token
    users(:urandom).forget_me
    assert_nil users(:urandom).remember_token
  end

  def test_should_remember_me_for_one_week
    before = 1.week.from_now.utc
    users(:urandom).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil users(:urandom).remember_token
    assert_not_nil users(:urandom).remember_token_expires_at
    assert users(:urandom).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    users(:urandom).remember_me_until time
    assert_not_nil users(:urandom).remember_token
    assert_not_nil users(:urandom).remember_token_expires_at
    assert_equal users(:urandom).remember_token_expires_at, time
  end

  def test_should_remember_me_default_two_weeks
    before = 2.weeks.from_now.utc
    users(:urandom).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil users(:urandom).remember_token
    assert_not_nil users(:urandom).remember_token_expires_at
    assert users(:urandom).remember_token_expires_at.between?(before, after)
  end
  
  def test_has_role
    assert_equal true, users(:urandom).has_role?('user_role')
    assert_equal true, users(:urandom).has_role?('admin_role')
    assert_equal false, users(:gnu).has_role?('tester_role')
    assert_equal true, users(:urandom).has_role?('tester_role') # admin has any role
    assert_equal true, users(:urandom).has_role?('staatskanzleivorsteher_role') # admin has *ANY* role
  end
    
protected
  def create_user(options = {})
    record = User.new({ :login => @login,
        :password => 'argl', 
        :password_confirmation => 'argl' }.merge(options))
    record.save
    record
  end
  
  def setup
    # runs before every test
    @login = 'new_user' # FIXME what for?
  end

end
