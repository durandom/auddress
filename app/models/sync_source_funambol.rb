class SyncSourceFunambol < SyncSource

  SE_HOME = Conf.path_to_data + '/data/syncevolution'
  SE_DATA_DIR = Conf.path_to_data + '/data/funambol'

  include SyncSourceModule

  after_create :check_dir, :setup_syncevolution

  def client=(client)
    # FIXME: save before setting config, else it is not stored...
    #  maybe move away from configurator
    self.configuration = client
  end

  def client
    configuration
  end

  def dirname
    "#{SE_DATA_DIR}/#{se_config}/"
  end

  def check_dir
    if File.exist?(dirname)
      raise "syncdir #{dirname} already exists"
    end
    raise "could not create #{dirname}" unless Dir.mkdir(dirname, 0700)
  end

  def se_config
    "#{user.id}-#{id}"
  end

  def se_user
    id
  end

  def se_password
    user.login
  end

  #def toggle_home
  #  se_home = 'data/syncevolution'
  #  @home ||= ENV['HOME'] # init @home
  #  ENV['HOME'] = ENV['HOME'] == se_home ? @home : se_home
  #end

  def syncevolution(args = '', source = 'addressbook')
    home = ENV['HOME']
    ENV['HOME'] = SE_HOME

    #stdin, stdout, stderr = Open3.popen3("#{Conf.syncevolution} #{se_config}")
    call = "#{Conf.syncevolution} #{args} #{se_config} #{source} 2>&1"
    e = IO.popen(call)
    stdout = e.readlines
    e.close
    if $?.exitstatus != 0
      logger.error "'#{call}' failed with #{$?.exitstatus}"
      logger.error stdout
    end
    ENV['HOME'] = home
  end



  def setup_syncevolution
    # setup a new config with all sources disabled with the funambol template
    syncevolution("--configure --source-property sync=none --template funambol", '')
    # set username, password and syncurl
    syncevolution("--configure --sync-property username=#{se_user} "+
        "--sync-property password=#{se_password} "+
        "--sync-property syncURL=#{Conf.funambol}")
    # set device id
    syncevolution("--configure --sync-property deviceId=sc-audr-#{se_config}")

    # set type to vcard 2.1 and the path to vcards
    path=Pathname.new(dirname).realpath.to_s
    syncevolution("--configure --source-property sync=refresh-from-client "+
        "--source-property type=file:text/x-vcard:2.1 "+
        "--source-property evolutionsource=#{path}") # addressbook

    # reset server data
    syncevolution

    # set mode to two-way
    syncevolution("--configure --source-property sync=two-way") # addressbook
  end

  def begin_sync
    @contacts = {}
    @deleted, @updated = [], []

    syncevolution

    dir = dirname
    d = Dir.new(dir)
    d.each do |idx|
      # only read numerical files
      next unless idx =~ /^\d+$/
      f = File.open(dir + idx)
      ConvertVcard.decode_vcards(f).each do |card|
        add_contact(card, idx)
      end
      f.close
    end
    d.close
    @contact_keys_begin = @contacts.keys
  end

  def end_sync
    # sync all changes to disk
    dir = dirname
    new = @contacts.keys - @contact_keys_begin
    (@updated + new).each do |idx|
      f = File.open(dir + idx, 'w')
      # Encode returns the string representation with no line wrapping
      #   default is 75 columns, but this breaks funambol
      f.write(@contacts[idx].encode(0))
      f.close
    end

    @deleted.each do |idx|
      begin
        File.delete(dir + idx)
      rescue Errno::ENOENT => e
        # file does not exist
        Rails::logger.error("SyncSourceFunambol #{se_config}")
        Rails::logger.error(e)
      end
    end

    # we have to sleep a second, because syncevolution relies on changed file mtime
    sleep 1
    syncevolution
  end

  def source_update_contact(contact, key)
    @updated << key
    contact
  end

  def source_delete_contact(contact, key)
    @deleted << key
  end


  def person_to_obj(person, contact = nil)
    card = ConvertVcard.to_vcard(person, :version => '2.1', :encode => true)
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
   # find the largest number in @contacts
   if m=@contacts.keys.collect{|i| i.to_i}.max
     (m + 1).to_s
   else
     '0'
   end
  end
  
  def get_key(contact)
    nil
  end

  def set_key!(contact, key)
    nil
  end
  
end
