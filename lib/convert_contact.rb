class ConvertContact

  def self.filter
    {
      :person => [:firstname, :lastname],
      :emails => [:email, :location]
    }
  end

  def self.to_person(contact)
    person = Person.new
    firstname, lastname = (contact.name || '').split ' ', 2
    person.firstname = firstname
    person.lastname = lastname

    contact.fields('email').each do |email|
      e = Email.new
      e.location = email['rel'] ? (email['rel'].split('#')).pop : nil
      e.email = email['address']
      person.emails << e
    end

    person
  end

  def self.to_contact(person, google, contact)
    #contact = Contacts::Contact.new(nil, "#{person.firstname} #{person.lastname}")
    unless contact
      contact = google.new_contact
    end
    contact.name = ERB::Util::html_escape("#{person.firstname} #{person.lastname}")

    emails = ''
    person.emails.with_link.each do |email|
      #primary=true

      emails += "<gd:email rel='http://schemas.google.com/g/2005#%s' address='%s'/>" %
      [
        email.location.blank? ? email.default_location : email.location,
        ERB::Util::html_escape(email.email)
      ]
    end
    contact.replace_fields('email', emails)

    contact
  end
end