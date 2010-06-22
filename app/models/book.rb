# This Class will hold the Addressbook of a User. A Addressbook contains many Person 
# FIXME: make book name unique
class Book < ActiveRecord::Base  
  DEFAULT_NAME = self.columns.select{|c| c.name == 'name'}.first.default
  IMPORT_NAME = '_import'
  TRASH_NAME = '_trash'

  #has_and_belongs_to_many :people, :order => 'people.firstname', :include => :link
  has_and_belongs_to_many :people, :order => 'people.lastname'
  belongs_to :user

  named_scope :default, :conditions => {:name => DEFAULT_NAME}
  #named_scope :include_people, :include => :people
  #named_scope :include_people_details, :include => { :people => [* Person.collection_details] }
  #after_create :create_ldap
  
  validates_presence_of :name

  # is this the default book
  def default?
    name == DEFAULT_NAME
  end

#  # FIXME do we need this function anyway?
#  def add(person)
#    # make sure the person also exists in this book
#    # we have to save first, because << does a save! which throws exceptions
#    # on validation errors
#    # FIXME: but this is also a problem, because .save does ldap save,
#    #    which requires that the person is already saved in this book.
#    #    so we have a circular dependency here.
#    rv = person.save
#    self.people << person if rv
#    return rv
#  end
#
#  # FIXME do we need this ?
#  # only removes person from the book
#  def remove(person)
#    self.people.delete person
#  end

  def includes_alike?(person)
    # create conditions
    # FIXME: is this cacheable? Maybe something like below
    #  maybe something with a Ruby Set?
    conditions = Person.details.inject({}) do |hash, detail|
      hash[detail] = person.send(detail)
      hash
    end
    people.find(:all, :conditions => conditions).each do |candidate|
      return true if candidate.collection_details_alike?(person)
    end
    return false
  end

  # checks if a person exists in this book.
  # we only match for details
  def off_includes_alike?(person)
    # create conditions
    # FIXME: is this cacheable?
    people.each do |candidate|
      return true if candidate.alike?(person)
    end
    return false
  end

  # expects an array of people_to_find in this book
  # returns only those people from people_to_find who are the same (except id)
  # as person.same?() - so its not the people from book which are returned, but
  # those who were in people_to_find
#  def find_same(people_to_find)
#    # FIXME: allow array and single person as parameter -> fix call in import.rb
#    rv = []
#    people_to_find.each do |person|
#      # we have to fiddle around here, because SQL treats numbers and null different
#      #conditions = 'firstname = ? AND lastname = ? AND person.id '
#      #conditions += person.new_record? ? 'is not ?' : '<> ?'
#      conditions = 'firstname = ? AND lastname = ?'
#      candidates = people.find(:all, :conditions =>
#          [conditions,
#           person.firstname, person.lastname]
#      )
#      candidates.each do |candidate|
#        rv << person if person.alike?(candidate)
#      end
#    end
#    return rv
#  end
  
#  def create_ldap
#    return unless Conf.store_ldap
#    BookLdap.setup_scope(user)
#
#    begin
#      if BookLdap.exists?('people')
#        ldap = BookLdap.find('people')
#      else
#        ldap = BookLdap.new
#      end
#      ldap.ou = 'people'
#
#      ldap.save
#    rescue
#      logger.fatal "LDAP Errors: " + ActiveLdap::ConnectionError.to_s
#    end
#  end

end
