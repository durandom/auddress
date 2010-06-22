# This Class holds Address records belonging to a People
class Address < PersonDetail

  # overwrites location= to do some sanity checks
  include PersonDetailLocation

  LDAP_DEFAULT_LOCATION = 'postalAddress'
  LOCATIONS = {
    nil => {:ldap => LDAP_DEFAULT_LOCATION},
    'work'  => {:ldap => LDAP_DEFAULT_LOCATION},
    'private'  => {:ldap => 'homePostalAddress'}
    #'registered' => {:ldap => 'registeredAddress'}
  }

  def display_address
    <<HERE
#{street} #{number}
#{zip} #{city}
#{country}
HERE
  end

  alias display display_address 
  
  def to_ldap_attributes
    if LOCATIONS.key?(location)
      rv = { LOCATIONS[location][:ldap] => display_address }
    else
      rv = { LDAP_DEFAULT_LOCATION => display_address }
    end
    if rv.key?(LDAP_DEFAULT_LOCATION)
      rv['postalCode'] = zip
      #rv['postOfficeBox'] = pobox
      #rv['st'] = state
      rv['street'] = street
    end
    return rv
  end

end
