require File.dirname(__FILE__) + '/../test_helper'

class PersonTest < ActiveSupport::TestCase
  fixtures :users

  def test_should_create_person
    assert_difference 'Person.count' do
      person = Person.new
      logger.info "in test_should_create_person, right after Person.new"
      person.user = users(:urandom)
      person.firstname = 'Tink'
      person.lastname = 'Tonk'
      person.organization = '#B4mad.Net Network'
      person.birthday = '1974-02-01 06:30'

      person.save
      
      assert !person.new_record?, "#{person.errors.full_messages.to_sentence}"
    end
    
  end

  def add_addresses(person, p = '')
    person.addresses << Address.new(
      :street => p+'street_1', :zip => p+'12345', :city => p+'city_1'
    )
    # Same City, different street
    person.addresses << Address.new(
      :street => p+'street_2', :zip => p+'12345', :city => p+'city_1'
    )
    # Different City
    person.addresses << Address.new(
      :street => p+'street_3', :zip => p+'67890', :city => p+'city_2'
    )

  end
  
  def test_update_with
    assert people(:hild).update_with!(people(:goern))
    assert_equal people(:hild).checksum, people(:goern).checksum
  end

  def test_update_with_filter
    assert people(:hild).update_with!(people(:goern), {:person => [:firstname]})
    assert_equal people(:hild).firstname, people(:goern).firstname
    assert people(:hild).lastname != people(:goern).lastname
  end

  def test_update_with_filter_detail
    add_addresses(people(:goern))
    filter = {:person => [:firstname], :addresses => [:city]}
    assert people(:hild).update_with!(people(:goern), filter)
    assert people(:hild).addresses.find_by_city('city_1')
    assert_nil people(:hild).addresses.find_by_street('street_1')
  end

  def test_update_with_detail
    add_addresses(people(:hild))
    person = Person.new()
    # this is left to be untouched, nothing changed
    person.addresses << Address.new(
      :street => 'street_1', :zip => '12345', :city => 'city_1'
    )
    # this should overwrite the second one,
    # because we have only changed the street
    person.addresses << Address.new(
      :street => 'street_new', :zip => '12345', :city => 'city_1'
    )
    # this is completely new
    person.addresses << Address.new(
      :street => 'street_new', :zip => '666', :city => 'city_666'
    )
    person.save

    a1_attr = people(:hild).addresses.find_by_street('street_1').attributes
    a2_attr = people(:hild).addresses.find_by_street('street_2').attributes
    a3_attr = people(:hild).addresses.find_by_street('street_3').attributes
    sleep 1

    assert people(:hild).update_with!(person)
    # address 1 should not be touched
    assert_equal people(:hild).addresses.find_by_street('street_1').attributes,
      a1_attr
    # address 2 should have been overwritten
    assert_equal people(:hild).addresses.find_by_street('street_new').id,
      a2_attr['id']
    # address 3 shouldnt be there
    assert_nil people(:hild).addresses.find_by_street('street_3')
    # new address should be there
    assert people(:hild).addresses.find_by_street('street_new')
    # and it should not have reused the old adress
    assert people(:hild).addresses.find_by_street('street_new').id != a3_attr['id']
  end
end
