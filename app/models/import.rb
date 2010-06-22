module Import
  # FIXME: somehow we should be able to read current_user also in models
  #  http://wiki.rubyonrails.org/rails/pages/Howto+Add+created_by+and+updated_by
  #  http://blog.notesake.com/2007/11/28/access-current-user-in-models/
  attr_accessor :count
  attr_accessor :user

  # clears all people from this import
  def clear!
    # FIXME: make this faster!
    user.import_book.people.each do |person| 
      person.destroy 
    end 
  end

  def save_person
    # dont import if the person already exists...
    #    book = user.book.default(:include => people)
    @book ||= user.book
    return false if @book.includes_alike?(@person)

    unless @person.save and @book.people << @person
      @person.logger.warn "person not saved"
      @person.logger.debug @person.errors.full_messages.to_sentence
    end
    # return true if no errorrs occured
    @person.errors.empty?
  end

  def import
    # how many where imported with success
    @count = 0
    User.transaction do
      prepare_import

      while read_next
        @person = Person.new
        @person.user = user
        read_details
        @count += 1  if save_person
      end
    end
    return true
  end

  # actually does the import, loops over all records
  # and adds them to the db
  def import_off
    # how many where imported with success
    @count = 0
    prepare_import

    import_people = []
    to_be_imported_people = []

    while read_next
      @person = Person.new
      @person.user = user
      read_details
      #@count += 1  if save_person
      import_people << @person
    end
    
    # now remove all people that are already in auddress
    book = user.book
    user_people = book.people.include_details.dup
    import_people.each do |person|
      rm_idx = user_people.each_with_index do |candidate, idx|
        break idx if person.alike?(candidate)
      end
      rm_idx.class == Fixnum ? 
        user_people.delete_at(rm_idx) : to_be_imported_people << person
    end
    
    # now import all people
    to_be_imported_people.each do |person|
      unless person.save and book.people << person
        person.logger.warn "person not saved"
        person.logger.debug YAML::dump(person.errors)
      else
        @count += 1
      end
    end

    return true
  end

end
