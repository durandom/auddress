class SyncSourceVcard < SyncSource

  include SyncSourceModule

  UID = 'X-AUDDRESS-UID'

  attr_reader :file

  before_create :check_file

  def filename
    Conf.path_to_data + "/data/vcard/#{user.id}/cards.vcf"
  end

  def check_file
    unless File.directory?(d=File.dirname(filename))
      FileUtils.makedirs(d, :mode => 0770)
    end
    raise "syncfile already exists" if File.exist?(filename)
  end

  def begin_sync
    # read vcard file
    #@file = "test/fixtures/files/vCards.vcf"
    @file = filename

    @contacts = {}

    if File.exist?(@file)
      ConvertVcard.decode_vcards(File.open(@file)).each do |card|
        add_contact(card)
      end
    end

    #@sync_item_keys = sync_items.collect {|s| s.key }
  end

  def end_sync
    # write vcard file
    f = File.open(@file, "w+", 0664)
    @contacts.values.each {|c| f << c}
    f.close
  end

  def person_to_obj(person, contact = nil)
    card = ConvertVcard.to_vcard(person)
    if contact and key = get_key(contact)
      set_key!(card, key)
    end
    card
  end

  def checksum_contact(contact)
    # FIXME: without .clone to_s prohibits adding new fields?
    #   c = Vpim::Vcard.create()
    #   c.to_s
    #   c << Vpim::DirectoryInfo::Field.create('FIELD', 'NEW')
    #   c.to_s # does not have the new field
    Digest::MD5.hexdigest(contact.clone.to_s)
  end

  def create_key(contact)
    key = checksum_contact(contact)
    while @contacts.has_key?(key)
      key = Digest::MD5.hexdigest(key)
    end
    key
  end
  
  def get_key(contact)
    contact.value(UID)
  end

  def set_key!(contact, key)
    if contact[UID]
      contact.field(UID).value = key
    else
      contact << Vpim::DirectoryInfo::Field.create(UID, key)
    end
  end
  
end