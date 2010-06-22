module SyncSourceModule

  def update_item!(item)
    #person_remote = Convert.to_person(@contacts[item.key])
    #person_remote.update_with!(item.person_remote, filter)

    # convert the person from the item to format of syncsource
    contact = person_to_obj(item.person, @contacts[item.key])
    assert_key!(contact, item.key)

    contact = source_update_contact(contact, item.key) if self.respond_to?(:source_update_contact)
    return false unless contact
    
    @contacts[item.key] = contact
    true
  end

  def add_item!(item)
    contact = person_to_obj(item.person)
    contact = source_add_contact(contact) if self.respond_to?(:source_add_contact)
    return false unless contact
    item.key = add_contact(contact)
    true
  end

  def delete_item(item)
    source_delete_contact(@contacts[item.key], item.key) if self.respond_to?(:source_delete_contact)
    @contacts.delete(item.key)
  end

  # returns all items which have changed
  def updated_items(time_frame = {})
    items = []
    sync_items.each do |item|
      next unless @contacts.has_key?(item.key)
      # contact is in our store and the checksum changed
      if (checksum = checksum(item) and checksum != item.checksum_remote) or
          ( self.respond_to?(:item_updated?) and
            self.item_updated?(item, @contacts[item.key]) )
        item.person_remote = Convert.to_person(@contacts[item.key], user)
        items << item
      end
    end
    items
  end

  # returns all contacts for which no syncitem exists
  def new_items(time_frame = {})
    items = []
    @contacts.each do |key, contact|
      unless sync_items.keys.include?(key)
        item = SyncItem.new
        item.key = key
        item.person_remote = Convert.to_person(contact, user)
        items << item
      end
    end
    items
  end

  # return all syncitems for which no contact exists
  def deleted_items(time_frame = {})
    items = []
    sync_items.each do |item|
      items << item unless @contacts.has_key?(item.key)
    end
    items
  end

  def add_contact(contact, key = nil)
    # add uid to card if it doesnt have it already
    key = assert_key!(contact, key)
    #key = get_key(contact) unless key
    #puts "add #{contact.name} #{contact.id}"
    if @contacts.has_key?(key)
      raise "duplicate key #{key} #{@contacts[key].to_s}"
    end
    @contacts[key] = contact
    key
  end

  def assert_key!(contact, key = nil)
    # make sure the contact has the key we want (if key is not nil)
    if key and key != get_key(contact)
      # we can trust set_key! to do the right thing
      set_key!(contact, key)
      return key
    end

    unless key = get_key(contact)
      key = create_key(contact)
      set_key!(contact, key)
    end
    key
  end

  def checksum(item)
    self.respond_to?(:checksum_contact) ? checksum_contact(@contacts[item.key]) : nil
  end

  def has_item?(item)
    @contacts.has_key?(item.key)
  end

end
