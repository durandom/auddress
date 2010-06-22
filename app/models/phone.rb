"""
This Class holdes Phone numbers, implements a subset of TEL TYPE as defined by 
RFC2426 a phone number could look like 
TEL;TYPE=work,voice,pref,msg:+1-213-555-1234
"""

class Phone < PersonDetail

  # overwrites location= to do some sanity checks
  include PersonDetailLocation

  # Just a number is probably not enough  
  #validates_numericality_of :number
  
  # This plugin http://code.google.com/p/validates-as-phone/
  # might be a good start
  #validates_as_phone :number, :message => "is not a valid phone number"
  # For now we just accept anything :)
  
  LDAP_DEFAULT_LOCATION = 'telephoneNumber'
  LOCATIONS = {
    'work'  => {:ldap => LDAP_DEFAULT_LOCATION},
    'home'  => {:ldap => 'homePhone'},
    'cell'  => {:ldap => 'mobile'},
    'pager' => {:ldap => 'pager'}
    #'car'   => {:ldap => ''}
  }

  # We take split into locations and capabilities from here
  # http://vpim.rubyforge.org/classes/Vpim/Vcard/Telephone.html
  # seems RFC2426 does not say which should be location or capability
  """ Location represent TEL TYPE parameters as defined by RFC2426 """
  def locations
    super + ['cell', 'pager']
  end

  """ Capabilities represent TEL TYPE parameters as defined by RFC2426 """
  def capabilities
    return [nil, 'voice', 'fax', 'msg', 'video'] # bbs modem isdn pcs
  end

  def display_number
    return number
  end

  def to_ldap_attributes
    if LOCATIONS.key?(location)
      { LOCATIONS[location][:ldap] => display_number }
    else
      { LDAP_DEFAULT_LOCATION => display_number }
    end
  end

end
