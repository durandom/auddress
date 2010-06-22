require File.dirname(__FILE__) + '/../test_helper'

class EmailTest < ActiveSupport::TestCase
  def setup
    @soll_locations = ["work", "home", "other" ]

  end

  # Replace this with your real tests.
  def test_locations
    assert_not_nil Email.new.locations
    assert_equal @soll_locations, Email.new.locations

  end
end
