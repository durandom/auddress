class SyncSourceGoogle < SyncSource

  include SyncSourceModule

  def begin_sync
    @contacts = {}
    @google = Contacts::Google.new('default', configuration)
    @google.all_contacts.each do |c|
      add_contact(c)
      #puts "add #{c.name} #{c.updated_at}"
    end
  end

  def end_sync
  end

  def handle_exception(err, contact)
    logger.error err
    logger.error contact.gmail.response_body(err.response)
    logger.error err.request
    id = contact.id || 'new contact'

    # "expected HTTPSuccess, got Net::HTTPConflict (409 Conflict)"
    case err.response.code.to_i
    when 400 # Error
      logger.error "SyncSourceGoogle error for #{id}"
      return false
    when 409 # Conflict
      logger.error "SyncSourceGoogle conflict for #{id}"
      return false
    else
      logger.error "SyncSourceGoogle conflict for #{id}"
      return false
    end

  end

  def source_update_contact(contact, key)
    begin
      #contact = @google.update(contact)
      contact.update!
    rescue Contacts::FetchingError => err
      return handle_exception(err, contact)
    end
    contact
  end

  def source_add_contact(contact)
    begin
      #contact = @google.create(contact)
      contact.create!
    rescue Contacts::FetchingError => err
      return handle_exception(err, contact)
    end
    contact
  end

  def source_delete_contact(contact, key)
    #@google.remove(contact)
    contact.delete!
  end

  def person_to_obj(person, contact = nil)
    ConvertContact.to_contact(person, @google, contact)
  end

  def filter
    ConvertContact.filter
  end

  def item_updated?(item, contact)
    # only use second precision
    contact.updated_at.to_i > item.updated_remote.to_i
  end

  def item_updated_at(item)
    @contacts[item.key].updated_at
  end

  def item_created_at(item)
    @contacts[item.key].updated_at
  end

  def get_key(contact)
    contact.id
  end

  def create_key(contact)
    raise "cannot create key for google"
  end

  def set_key!(contact, key)
    contact.id = key
  end

end