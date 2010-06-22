module PersonDetailWithLink
  def with_link
    load_target
    if proxy_owner.link.respond_to?(proxy_reflection.name)
      # FIXME: make this cacheable:
      #   . set a loaded variable
      #   . reset loaded variable on self.reload
      # linked attributes come first
      proxy_owner.link.send(proxy_reflection.name) + @target
    else
      @target
    end
  end
end

class Person < ActiveRecord::Base
  # attributes => true helps accessing multiple models in one form
  # much cleaner code than now, and it work with ajax
  # see http://jamesgolick.com/2007/12/5/introducing-attributefu-multi-model-forms-made-easy
  has_many :addresses, :dependent => :destroy, :extend => PersonDetailWithLink
  has_many :phones, :dependent => :destroy, :extend => PersonDetailWithLink
  has_many :emails, :dependent => :destroy, :extend => PersonDetailWithLink

  accepts_nested_attributes_for :addresses, :phones, :emails, 
    :allow_destroy => true,
    # reject empty attributes, except location and capbility as they cannot be empty
    :reject_if => proc { |attr|
      attr.reject { |attr_name,v|
        ['location','capability'].include?(attr_name)
      }.all?{|attr_name,value| value.blank? }
    }
  
  has_and_belongs_to_many :books
  belongs_to :user

  has_one :link, :class_name => 'PersonLink' # we are the destination
  has_many :person_links, :dependent => :destroy,
    :foreign_key => 'source_person_id' # where  we are the source

  # in case we have been invited, this is the route where we came from
  has_one :link_request, :dependent => :destroy

  has_and_belongs_to_many :duplicates, :class_name => 'Person',
    :join_table => 'people_duplicates', 
    :foreign_key => 'person_id', :association_foreign_key => 'duplicate_id'

  has_and_belongs_to_many :false_duplicates, :class_name => 'Person',
    :join_table => 'people_false_duplicates',
    :foreign_key => 'person_id', :association_foreign_key => 'duplicate_id'

#  has_and_belongs_to_many :false_duplicate_targets, :class_name => 'Person',
#    :join_table => 'people_false_duplicates',
#    :association_foreign_key => 'person_id', :foreign_key => 'duplicate_id'
#  has_and_belongs_to_many :duplicate_targets, :class_name => 'Person',
#    :join_table => 'people_duplicates',
#    :association_foreign_key => 'person_id', :foreign_key => 'duplicate_id'


  validates_presence_of :user
  # FIXME: Do we also accept persons without a name?
  #  maybe we take a detail (e.g. email) as the default lastname?
  #validates_presence_of :lastname

  #FIXME make access control in the model
  # see 'model security' plugin by Bruce Perens
  # http://railsforum.com/viewtopic.php?id=2632
  # 
  #   before_destroy :assert_user
  
  # ldap representation of me
  # should not be needed from outside...
  #attr_reader :ldap

  #def after_initialize
  #  puts "honk #{self.id}"
  #end

  # FIXME photo has to be a checksum of the photo and to be stored in the filesystem
  #  use a chksum to make it comparable
  def self.details_except
    [:id, :user_id, :created_at, :updated_at]
  end

  # we can compare two persons with .same?
  acts_as_comparable :except => details_except #, :attrs_map => {:firstname => Proc.new{|p| p.firstname.to_s}}
  
  #after_save :save_ldap
  after_destroy :photo_remove

  def self.details
    #[:title, :firstname, :lastname, :organization, :birthday, :photo, :nickname, :url]
    column_names.collect { |n| n.to_sym } - details_except
  end

  def details
    self.class.details
  end

  def self.collection_details
    [:emails,:addresses,:phones]
  end
  
  def collection_details
    self.class.collection_details
  end

  #default_scope :include => :link
  named_scope :include_details, :include => [* self.collection_details ]
  # FIXME these scopes might need optimization, maybe use a join?
  #named_scope :with_duplicates,
  #  :conditions => 'id in (select person_id from people_duplicates)'
  named_scope :include_duplicates,
    :include => [:duplicates]
  named_scope :include_false_duplicates,
    :include => [:false_duplicates]
  named_scope :duplicates, :include => [:duplicates],
    :conditions => "people_duplicates.person_id is not NULL"

  # also make these details accessible, which also prohibits other to be set
  # via .attributes= or new(attributes)
  attr_accessible *self.details
  attr_accessible *self.collection_details.collect {|d| d.to_s + '_attributes' }

  # Overwrite details accessor to return link value
  self.details.each do |detail|
    class_eval(<<-EOS)
      def #{detail}        
        unless link.respond_to?(:#{detail})
          self.read_attribute(:#{detail})
        else
          link.send(:#{detail})
          #d = link.send(:#{detail})
          #return d.to_s.empty? ? self.read_attribute(:#{detail}) : d
        end
      end
    EOS
  end

  # creates photo on disk, even before save. If you dont call save after
  # setting the photo with photo= the information is discarded and a stale
  # file persists on disk.
  # FIXME: maybe improve this by storing the file in a tempfile
  def photo=(photo)
    return false unless user
    unless photo.blank?
      # remove the existing photo
      photo_remove # unless self.photo.blank?

      # Find a new unique filename
      random = ActiveSupport::SecureRandom.hex(16)
      while (File.exist?(user.photo_path + random))
        random = ActiveSupport::SecureRandom.hex(16)
      end

      f = File.new(user.photo_path + random, "w+")
      f.write(photo)
      f.close
      write_attribute(:photo, random)
    else
      # remove photo
      photo_remove
      write_attribute(:photo, nil)
    end
  end

  def photo_file
    user.photo_path + photo unless photo.blank?
  end

  # number of items per page, used for pagination plugin
  def self.per_page
    50
  end

  # return a clone of this person, with all details cloned as well
  # all timestamps set to nil
  def clone_deep
    c = self.clone :include => collection_details
    c.updated_at = nil
    c.created_at = nil
    self.collection_details.each do |detail|
      c.send(detail).each do |d|
        d.created_at = nil
        d.updated_at = nil
        d.person_id = nil
      end
    end
    c
  end
  
  def display_name
    if not firstname.to_s.empty? or not lastname.to_s.empty?
      dn = [firstname, lastname].join(' ')
    elsif not organization.nil?
      dn = organization
    else
      dn = "Contact #(#{id.to_s})"
    end
  end

  def collection_details_alike?(person)
    collection_details.each do |prop_name|
      self_props = self.send(prop_name).with_link
      # we have to dup, because we delete_at later and here we dont want
      #   to work on the association itself
      person_props = person.send(prop_name).with_link.dup
      return false if self_props.length != person_props.length
      # compare every property of myself
      self_props.each do |prop|
        found = false
        # with every property of the comparator
        person_props.each_with_index do |person_prop, index|
          # if they are the same
          if prop.same?(person_prop)
            # remove it from the list of comparisons
            person_props.delete_at(index)
            found = true
            break
          end
        end # end loop through comparator props
        # If we havent found anything
        return false unless found
      end
    end
    return true
  end
  
  def alike?(person)
    #logger.warn YAML::dump self.differences(person)
    if self.same?(person)
      return collection_details_alike?(person)
    end    
    return false
  end

  # returns true if the person could be a duplicate
  def duplicate?(person)
    return false if self.id == person.id
    # FIXME: more sophisticated dup check, please
    #self.display_name == person.display_name
    self.firstname == person.firstname
  end



  # Filter is a hash of attributes that should be updated
  #  if no filter, everything is updated
  # person.update_with!(person2, :person => [:firstname], :emails => [:email])

  def update_with!(src, *args)
    #src = person.clone_deep

    filter = args.extract_options!
    # no filter given, build default filter
    if filter.empty?
      filter = { :person => details}
      collection_details.each do |detail|
        # now this is perverted, but its just one line
        #  => filter[:emails] = Email.details
        filter[detail] = detail.to_s.singularize.titleize.constantize.details
      end
    end

    # remove all linked in attributes, so we dont update something in the
    # person which already exists in the link
    if self.link
      filter[:person].each do |attr|
        filter[:person].delete(attr) if src.send(attr) == self.link.send(attr)
      end
    end
    # update all single details that are specified in the filter
    self.attributes = src.attributes.symbolize_keys.slice(*filter[:person])

    collection_details.each do |detail|
      if filter.has_key?(detail)
        # Save comparable_options (from acts_as_comparable)
        comp_options = detail.to_s.singularize.titleize.constantize.comparable_options.dup
        comp_options[:only] = filter[detail]

        self_details = self.send(detail).with_link.dup
        src_details  = src.send(detail).dup

        diffs={}
        src_details.each_with_index do |src_detail, src_idx|
          self_details.each_with_index do |self_detail, self_idx|
            if src_detail and self_detail
              diff = self_detail.differences(src_detail, comp_options)
              if diff.empty?
                # Both are the same, so we dont have to touch anything
                # set the array elemnts to nil, so we'll skip them later
                src_details[src_idx] = nil
                self_details[self_idx] = nil
                # also remove any references from earlier comparisons
                diffs.delete(src_idx)
                diffs.each_key { |k| diffs[k].delete(self_idx) }
                # even delete those elements that dont compare to another anymore
                #  because we just removed the only comparison left
                diffs.delete_if { |k,v| v.empty? }
                break
              elsif diff.length < filter[detail].length
                # they differ in some, but not in all attributes
                #  so save the number of differences to decide later which to use
                diffs[src_idx] ||= {}
                diffs[src_idx][self_idx] = diff.length
              end
              # If the differ in all attributes, its likley a complete new detail
              #  so we'll create a new one later
            end
          end
        end

        # remaining src_details have to be promoted to self_details
        src_details.each_with_index do |src_detail, src_idx|
          # skip nil values, they have been already sorted out as identical
          next unless src_detail
          if diffs.has_key?(src_idx)
            # we'll update a detail
            # now find the one with the least differences
            self_idx, diff = diffs[src_idx].inject do |memo, obj|
              obj[1] < memo[1] ? obj : memo 
            end
            # remove this from the list
            diffs.delete(src_idx)
            diffs.each_key { |k| diffs[k].delete(self_idx) }
            diffs.delete_if { |k,v| v.empty? }
            # FIXME: dont use update_attributes! but update_attributes
            #   and handle save errors? Or can we rely on correct attributes?
            self_details[self_idx].update_attributes!(
              src_detail.attributes.symbolize_keys.slice(*filter[detail]))
            # and remove it from the array, we dont need to touch it anymore
            self_details[self_idx] = nil
          else
            # add the src_detail to self
            new_detail = src_detail.class.new(
              src_detail.attributes.symbolize_keys.slice(*filter[detail])
            )
            self.send(detail).send(:push, new_detail)
          end
        end

        # any remaining self_details have to be deleted
        self_details.each do |self_detail|
          self_detail.destroy if self_detail and self_detail.person_id == self.id
        end
      end
    end
    # because we already saved collection details we can also save ourselves
    self.save 
  end
  
  def merge!(person)
    src = person.clone_deep

    # only overwrite non existing attributes
    details.each do |prop|
      if attr = self.read_attribute(prop) and attr == ''
        # eval "self.#{prop} ||= src.#{prop}"
        self.write_attribute(prop, src.read_attribute(prop))
      end
    end

    collection_details.each do |prop_name|
      self_details = self.send(prop_name)
      src.send(prop_name).each do |detail|
        # check if detail exists
        does_not_exist = self_details.each do |self_detail|
          break if self_detail.same?(detail)
        end
        self.send(prop_name).send(:push, detail) if does_not_exist
      end
    end
    return true
  end

  def to_txt(with_keys = false)
    if with_keys
      (details.collect {|d| "#{d}\t" + self.send(d).to_s}).join("\n")
    else
      (details.collect {|d| self.send(d).to_s}).join("\n")
    end
  end

  def to_txt_deep(with_keys = false)
    if with_keys
      (details.collect {|d| "#{d}\t" + self.send(d).to_s}).join("\n") +
        (collection_details.collect do |detail|
          self.send(detail).collect {|d| d.to_txt(true) }
        end
      ).join("\n")
    else
      (details.collect {|d| self.send(d).to_s}).join("\n") +
        (collection_details.collect do |detail|
          self.send(detail).collect {|d| d.to_txt }
        end
      ).join("\n")
    end
  end


  def checksum
    Digest::MD5.hexdigest(self.to_txt)
  end

  def checksum_deep
    checksums = [self.checksum]
    collection_details.each do |d|
      checksums += self.send(d).collect {|i| i.checksum}
    end
    Digest::MD5.hexdigest(checksums.sort.join(''))
  end

  def event_create
    user.events << Event.person_create(self)
  end

  def event_destroy
    user.events << Event.person_destroy(self)
  end

  def event_update
    user.events << Event.person_update(self)
  end

  # This is called after_save of a Person and writes the Person to the LDAP Directory Server
  # display_name is used as the cn, if display_name changed the Person is written to LDAP again
  # resulting in a new and a old Person within LDAP
  # display_name := 'firstname lastname' or 'no displayname <randnum>'
#  def save_ldap
#    # FIXME: ldap should run out of the request
#    #  good start http://playtype.net/past/2008/10/2/workling_version_03_released/
#    return unless Conf.store_ldap
#
#    # First we collect the users, where we want to save this person
#    users = [user]   # the owner of that person
#    # and all default books that the user is in
#    users = users.concat(books.collect {|b| b.user if b.default? }).uniq
#
#    users.each do |user_scope|
#      begin
#        # FIXME: create PersonLdap
#        #PersonLdap.ldap_mapping(:prefix => 'ou=people,cn=' + user.login,
#        #                        :dn_attribute => 'cn')
#
#        PersonLdap.setup_scope(user_scope)
#        # FIXME: if person exists, make sure it is really the same person
#        #   for LDAP cn=display_name, but in audress 2 people can have the
#        #   same display_name
#        #   solution: save person_id in ldap. modify first_name to have
#        #             a unique display_name and therefore cn
#        if PersonLdap.exists?(display_name)
#          ldap = PersonLdap.find(display_name)
#        else
#          ldap = PersonLdap.new
#        end
#
#        # FIXME: if display name has changed, we have to remove this entry first!
#        ldap.cn = display_name
#        # OPTIMIZE: sn is required by inetOrgPerson objectclass, could be fn if sn is not present
#        if not lastname.empty?
#          ldap.sn = lastname.strip
#        else
#          ldap.sn = 'no lastname'
#        end
#
#        # OPTIMIZE: do this more generic, DRY
#        emails.each do |email|
#          ldap.attributes = email.to_ldap_attributes
#        end
#
#        phones.each do |phone|
#          ldap.attributes = phone.to_ldap_attributes
#        end
#
#        addresses.each do |address|
#          ldap.attributes = address.to_ldap_attributes
#        end
#
#        # FIXME write birthday and org to LDAP
#        if birthday
#          ldap.birthDate = birthdday.to_s
#        end
#
#        if organization
#          ldap.org = organization
#        end
#
#        ldap.save
#        # FIXME: what to do with errors?
#        # we should rollback and do not save, flash a error on the WUI
#      rescue
#        logger.fatal "LDAP Errors: " + ActiveLdap::ConnectionError.to_s
#      end
#    end # users.each
#  end

  private
  def photo_remove
    # removes the photo file, if file is nil we get a directory which raises
    # EISDIR exception
    begin
       if f = photo_file
         File.unlink(f)
       end
    rescue Errno::ENOENT, Errno::EISDIR
    end
  end

end
