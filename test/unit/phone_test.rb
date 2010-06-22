require File.dirname(__FILE__) + '/../test_helper'

class PhoneTest < ActiveSupport::TestCase
  def test_phone
    p = Phone.new :location => 'home', :capability => 'cell', :country => 49, :area => 228, :prefix => 0, :number => 9659, :extension => 033

    assert_not_nil p
    assert_equal 'home', p.location
    p.location = 'work'
    assert_equal 'work', p.location
    assert_equal 49, p.country
    assert_same(228, p.area)
    
    ### OPTIMIZE we assert rails getters/setters work correctly... dont we?
  end
end
