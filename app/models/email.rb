class Email < PersonDetail

  # overwrites location= to do some sanity checks
  include PersonDetailLocation

  LDAP_DEFAULT_LOCATION = 'mail'
  LOCATIONS = {
    nil => {:ldap => LDAP_DEFAULT_LOCATION},
    'work' => {:ldap => LDAP_DEFAULT_LOCATION},
    'home' => {:ldap => LDAP_DEFAULT_LOCATION}, # could be 'homeMail'
    'other' => {:ldap => LDAP_DEFAULT_LOCATION} # could be 'otherMail'
  }

  def email_address_with_name
    "\"#{person.display_name}\" <#{email}>"
  end

  def locations
    super << 'other'
  end
  
  def to_ldap_attributes
    if LOCATIONS.key?(self.location)
      { LOCATIONS[self.location][:ldap] => self.email }
    else
      { LDAP_DEFAULT_LOCATION => self.email }
    end
  end


end
