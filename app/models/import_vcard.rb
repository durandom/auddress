class ImportVcard
  include Import

  attr_accessor :file

  # This will set up the Vcard object and load the file just uploaded into the object
  def prepare_import
    # FIXME: maybe we can leave this as an iterator?
    # convert to array
    @cards = ConvertVcard.decode_vcards(@file)
  end
  
  # should read the next entry to be imported
  def read_next
    @card = @cards.shift
  end
  
  def read_details
    @person = ConvertVcard.to_person(@card, @person)
  end
  
end
