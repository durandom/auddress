module Vpim
  class DirectoryInfo
    class Field
      # we dont want the raw value, but the decoded one
      def value_raw
        value
      end
    end
  end
end

class ConvertVcard

  def self.decode_vcards(file)
    cards = []
    file.read.scan(/(BEGIN:VCARD.*?END:VCARD)/mi) do |card_s|
      begin
        card = Vpim::Vcard.decode(card_s.to_s).first
        cards << card if card
      rescue Vpim::InvalidEncodingError => e
        Rails::logger.error "catched Vpim::InvalidEncodingError"
        Rails::logger.error card_s
        # clean the backtrace before dump
        bc = Rails::backtrace_cleaner
        bc.add_silencer { |line| not line.start_with? 'app' }
        Rails::logger.error bc.clean(e.backtrace).join("\n")
      end
    end
    cards
  end



  def self.to_person(card, person = nil)
    person ||= Person.new
    #Rails::logger.warn(card.to_s)
    person.firstname = card.name.given
    person.lastname = card.name.family
    if card.name.given.empty? and card.name.family.empty?
      person.lastname = card.name.fullname
    end

    card.telephones.each do |phone|
      p = Phone.new
      p.number = phone.to_s
      p.capability = phone.capability.first || nil
      p.location = phone.location.first || nil
      # FIXME: honor 'preferred' setting in vcard email?
      person.phones << p
    end

    card.emails.each do |email|
      e = Email.new
      e.email = email.to_s
      e.location = email.location.first || nil
      # FIXME: honor 'preferred' setting in vcard email?
      person.emails << e
    end

    card.addresses.each do |address|
      a = Address.new
      a.country = address.country
      a.street = address.street
      a.zip = address.postalcode
      a.city = address.locality
      a.country = address.country
      a.location = address.location.first || nil
      person.addresses << a
    end

    # org.second would be the department
    person.organization = card.org.first if card.org
    person.birthday = card.birthday if card.birthday
    person.title = card.field('TITLE').value if card.field('TITLE')
    person.nickname = card.field('NICKNAME').value if card.field('NICKNAME')
    # FIXME: We need more url types (e.g. homepage)
    #  How to parse a url on correctness?
    person.url = card.url.uri.to_s.sub(/\\/, '') if card.url

    # FIXME: better do that with attachment_fu
    # see also http://paulbarry.com/articles/2008/04/19/serving-images-stored-in-the-database-with-rails
    card.photos.each_with_index do |photo, i|
      if photo.format
        # the format of the value. This is supposed to be an "iana defined"
        # identifier (like "image/jpeg"), but could be almost anything
        # (or nothing) in practice. Since the parameter is optional, it may be "".

        # FIXME: convert to jpeg if not set, or guess the format
        #photo.format.gsub('/', '_')
      else
        # You are your own if PHOTO doesn't include a format. AddressBook.app
        # exports TIFF, for example, but doesn't specify that.
        #file += 'tiff'
        # hmmm. mine seems to export jpeg?
      end
      person.photo = photo.to_s
      # we only use the first photo
      break
    end
    person
  end

  # used to create fields. converts to quoted-printable if needed
  def self.field(name, value, params = {})
    if @@encode and value.class==String and
        value != qvalue=value.to_a.pack('M*').chomp.chop
      params['ENCODING'] = 'QUOTED-PRINTABLE'
      value = qvalue
    end
    Vpim::DirectoryInfo::Field.create(name, value, params)
  end


  def self.to_vcard(person, *args)
    opts = args.extract_options!
    @@encode = opts[:encode] ? opts[:encode] : nil
    version =  (opts[:version] == :v2 or opts[:version] == '2.1') ? :v2 : :v3

    card = Vpim::Vcard.create
    card.field('VERSION').value = '2.1' if version == :v2
    # "#{last};#{first};#{middle};#{prefix};#{suffix}"
    card << field('N', "#{person.lastname};#{person.firstname};;;")
    card << field('FN', person.display_name)
    #"ORG", "#{organization_name};#{department_name}"
    card << field('ORG',"#{person.organization}") unless person.organization.to_s.empty?
    card << field('TITLE',"#{person.title}") unless person.title.to_s.empty?

    card << field('BDAY', person.birthday) if person.birthday
    card << field('NICKNAME', person.nickname) unless person.nickname.to_s.empty?
    card << field('URL', person.url) unless person.url.to_s.empty?

    person.emails.with_link.each do |email|
      if version == :v2
        card << field("EMAIL;#{email.location.upcase}", email.email)
      else
        card << field('EMAIL', email.email, 'TYPE' => [email.location])
      end
      #card << field('EMAIL', 'type' => ['INTERNET', email.location, 'pref'])
    end

    person.addresses.with_link.each do |a|
      value = ";;#{a.street};#{a.city};;#{a.zip};#{a.country}"
      if version == :v2
        card << field("ADR;#{a.location.upcase}", value)
      else
        # add 'PREF' to TYPE array
        #  address_str = [street, street2, street3, city, state, postal_code, country]
        card << field('ADR', value, 'TYPE' => [a.location])
      end
    end

    person.phones.with_link.each do |p|
      if version == :v2
        name = 'TEL'
        name += ";#{p.capability.upcase}" unless p.capability.to_s.empty?
        name += ";#{p.location.upcase}"
        card << field(name, p.display_number)
      else
        params = [p.location]
        params << p.capability unless p.capability.to_s.empty?
        card << field('TEL', p.display_number, 'TYPE' => params)
      end
    end

    Vpim::Vcard::Maker.make2(card) do |maker|
      maker.add_photo do |photo|
        f = File.new(person.photo_file)
        photo.image = f.read
        f.close
        #  photo.link
        photo.type = ''
      end
    end if File.file?(person.photo_file)

    card

      #maker.add_impp(url) {|impp| ...}
      # preferred: true - set if this is the preferred address
      # location: home, work, mobile - location of address
      # purpose: personal,business - purpose of communications

      #maker.add_note(note)
  end


  def self.off_to_vcard(person, *args)
    opts = args.extract_options!

    version = opts[:version] ? opts[:version] : '3.0'

    # Create a new 2.1 vCard.
    #card = Vpim::DirectoryInfo.create(
    #  [
    #    Vpim::DirectoryInfo::Field.create('VERSION', version)
    #  ], 'VCARD')




    card = Vpim::Vcard::Maker.make2 do |maker|
      maker.add_name do |name|
        name.given = person.firstname.to_s
        name.family = person.lastname.to_s
        #name.additional = person.lastname.to_s
        #name.prefix = person.lastname.to_s
        #name.suffix = person.lastname.to_s
      end

      person.addresses.each do |address|
        maker.add_addr do |a|
          #addr.preferred = true
          a.location = address.location
          a.street = address.street
          a.locality = address.city
          a.country = address.country
          a.postalcode = address.zip
          #delivery
          #extended
          #pobox
          #region
        end
      end

      person.emails.each do |email|
        maker.add_email(email.email) do |e|
          #e.preferred = true
          e.location = email.location
          #e.format
        end unless email.email.strip.empty?
      end

      person.phones.each do |phone|
        maker.add_tel(phone.display_number) do |p|
          p.location = phone.location
          # FIXME: why is capability not accepted?
          p.capability = phone.capability unless phone.capability.to_s.empty?
          #p.preferred = true
        end unless phone.display_number.strip.empty?
      end

      #maker.add_impp(url) {|impp| ...}
      # preferred: true - set if this is the preferred address
      # location: home, work, mobile - location of address
      # purpose: personal,business - purpose of communications

      #maker.add_note(note)

      maker.add_photo do |photo|
        photo.image = person.photo
      #  photo.link
        photo.type = ''
      end if person.photo

      maker.add_url(person.url) if person.url

      maker.birthday = person.birthday if person.birthday
      maker.nickname = person.nickname if person.nickname
      maker.org = person.organization if person.organization
      maker.title = person.title if person.title
    end
    card.field('VERSION').value = version
    card
  end
  
end




