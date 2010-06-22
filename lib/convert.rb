class Convert
  def self.to_person(from, user = nil)
    # FIXME make this more generic by guessing the converter class
    if from.class == Vpim::Vcard
      person = ConvertVcard.to_person(from)
    #elsif from.class == Contacts::Contact
    elsif from.class == Contacts::Google::Contact
      person = ConvertContact.to_person(from)
    else
      raise "Cant convert from #{from.class} to Person"
    end
    person.user = user
    person
  end
end