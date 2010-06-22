require File.dirname(__FILE__) + '/../test_helper'

class SyncSourceTest < ActiveSupport::TestCase
  # replace with your own token
  # e.g. create a google sync in development
  #  then in script/console do
  #  SyncSourceGoogle.find(:all).each {|s| puts "#{s.user.login} #{s.token}" }
  GOOGLE_TOKEN = "CMyNi8lAEJn6_JIG"

  def teardown
    puts @engine.log if @engine
  end
  
  def do_sleep
    sleep 0
  end

  def vcard(firstname, lastname)
    return "BEGIN:VCARD
VERSION:3.0
N:#{lastname};#{firstname};;;
FN:#{firstname} #{lastname}
X-AUDRESS-UID:c9991abb4c8ca4aa59212c0208ff9721
END:VCARD
"
  end

  def vcard_create_source
    @sync_source = SyncSourceVcard.new(:user => users(:urandom))
    File.delete(@sync_source.filename) if File.exists?(@sync_source.filename)
    @sync_source.save

    @sync_source_alt = SyncSourceVcard.find(@sync_source)
  end

  def vcard_create_conflict(auto_resolve = nil)
    vcard_create_source
    @engine = SyncEngine.new(:sync_source => @sync_source)
    @engine.sync
    do_sleep

    #change something on both sides
    person = users(:urandom).book.people.first
    firstname, lastname = person.firstname, person.lastname
    # change lastname and add a title
    person.lastname = 'Changed'
    person.title = 'AudressTitle' unless auto_resolve
    person.save
    # also change lastname but add a telephone number
    cards = File.open(@sync_source.file, 'r').read
    cards["N:#{lastname}"] = "N:Changed in Vcard"  unless auto_resolve
    cards["N:#{lastname}"] = "N:Changed"  if auto_resolve
    cards["FN:#{firstname} #{lastname}"] = "FN:#{firstname} #{lastname}
TEL;TYPE=work,voice:0800-DONTCALL" unless auto_resolve

    f = File.open(@sync_source.file, 'w+')
    f << cards
    f.close
    @engine.sync
    assert_equal(@sync_source.sync_items.conflict.length, 1)  unless auto_resolve
  end


  
  def test_vcard_source
    do_sleep
    vcard_create_source
    @engine = SyncEngine.new(:sync_source => @sync_source)
    @engine.sync
    assert_equal users(:urandom).book.people.length,
      File.open(@sync_source.file).grep(/BEGIN:VCARD/).length

    # add a person to audress
    do_sleep
    person = Person.new(:firstname => 'SyncTest', :lastname => 'Audress')
    person.user = users(:urandom)
    users(:urandom).book.add(person)
    @engine.sync
    deny_empty File.open(@sync_source.file).grep(/N:Audress;SyncTest/)

    # add a person to vcard
    do_sleep
    f = File.open(@sync_source.file, 'a')
    vcard_lastname = 'Vcard'
    vcard_firstname = 'SyncTest'
    f << vcard(vcard_firstname, vcard_lastname)
    f.close
    @engine.sync
    assert (users(:urandom).book.people.find_by_lastname(vcard_lastname))

    # update person in audress
    do_sleep
    person.lastname = 'Changed'
    person.save
    @engine.sync
    assert_empty File.open(@sync_source.file).grep(/N:Audress;SyncTest/)
    deny_empty File.open(@sync_source.file).grep(/N:Changed;SyncTest/)

    # update person in vcard
    do_sleep
    f = File.open(@sync_source.file)
    cards = f.read
    f.close
    new_lastname = vcard_lastname + 'Changed'
    cards[vcard(vcard_firstname, vcard_lastname)] =
      vcard(vcard_firstname, new_lastname)
    f = File.open(@sync_source.file, 'w+')
    f << cards
    f.close
    @engine.sync
    assert (users(:urandom).book.people.find_by_lastname(new_lastname))

    # delete person in audress
    do_sleep
    person.destroy
    @engine.sync
    assert_empty File.open(@sync_source.file).grep(/N:Changed;SyncTest/)

    # delete person in vcard
    do_sleep
    f = File.open(@sync_source.file)
    cards = f.read
    f.close
    cards[vcard(vcard_firstname, new_lastname)] = ""
    f = File.open(@sync_source.file, 'w+')
    f << cards
    f.close
    @engine.sync
    assert_nil users(:urandom).book.people.find_by_lastname(new_lastname)
  end

  def test_vcard_conflict_resolve_local
    vcard_create_conflict

    # now resolve local
    @sync_source.sync_items.conflict.first.resolve(:local)
    @engine.sync
    assert_empty File.open(@sync_source.file).grep(/N:Changed in Vcard;/)
    deny_empty File.open(@sync_source.file).grep(/N:Changed;/)
    deny_empty File.open(@sync_source.file).grep(/TITLE:AudressTitle/)
  end

  def test_vcard_conflict_resolve_remote
    vcard_create_conflict

    # now resolve remote
    @sync_source.sync_items.conflict.first.resolve(:remote)
    @engine.sync
    deny_empty File.open(@sync_source.file).grep(/N:Changed in Vcard;/)
    assert_empty File.open(@sync_source.file).grep(/N:Changed;/)
    person = users(:urandom).book.people.find_by_lastname('Changed in Vcard')
    assert person
    assert person.phones.find_by_number('0800-DONTCALL')
  end

  def test_vcard_conflict_resolve_merge
    vcard_create_conflict

    # now resolve merge
    @sync_source.sync_items.conflict.first.resolve(:merge)
    @engine.sync
    deny_empty File.open(@sync_source.file).grep(/N:Changed in Vcard;/)
    assert_empty File.open(@sync_source.file).grep(/N:Changed;/)
    deny_empty File.open(@sync_source.file).grep(/TITLE:AudressTitle/)
    person = users(:urandom).book.people.find_by_lastname('Changed in Vcard')
    assert person
    assert person.phones.find_by_number('0800-DONTCALL')
  end

  def test_vcard_conflict_resolve_auto
    vcard_create_conflict('auto_resolve')
    assert_empty(@sync_source.sync_items.conflict)
  end



  def test_google_contacts_api
    google = Contacts::Google.new('default', GOOGLE_TOKEN)
    c = google.contacts(:limit => 1).first
    # change the name
    c.name = 'Horst' + rand(999).to_s
    # change first email
    c.emails[0] = 'Horst@domain' + rand(999).to_s + '.com'
    # add one email
    c.emails << 'Horst@domain' + rand(999).to_s + '.com'
    #puts "#{c.name} #{c.emails.join(',')}"
    c = google.update(c)
    #puts "#{c.name} #{c.emails.join(',')}"
    google.remove(c)
  end

  def test_google
    local_email = 'local' + rand(999).to_s + '.com'
    remote_email = 'remote@' + rand(999).to_s + '.com'

    google = Contacts::Google.new('default', GOOGLE_TOKEN)
    google.all_contacts.each do |c|
      rv = c.fields('email').each do |f|
        email = f['address']
        if Email.find_by_email(email) or
            email == local_email or email == remote_email
          puts "Found #{email} on google -> removing"
          break
        end
        p = users(:urandom).book.people.select {|p| p.display_name == c.name }
        unless p.empty?
          puts "Found #{c.name} on goolge -> removing"
          break
        end
      end
      c.delete! if rv == nil
    end


    sync_source = SyncSourceGoogle.new(:user => users(:urandom))
    sync_source.configuration = GOOGLE_TOKEN
    sync_source.save
    @engine = SyncEngine.new(:sync_source => sync_source)
    @engine.sync

    gc = google.all_contacts
    # should have the same number of contacts now
    assert_equal gc.length, users(:urandom).book.people.length
    p1 = people(:goern)
    assert gc.select {|c| c.name == p1.display_name }

    sleep 0
    # Now change something on both sides
    c1 = (gc.select {|c| c.name == p1.display_name }).first
    person = ConvertContact.to_person(c1)
    e = person.emails.first
    e.email = remote_email
    c1 = ConvertContact.to_contact(person, nil, c1)
    #puts c1.fields('email')

    begin
      c1.update!
    rescue Contacts::FetchingError => err
      puts Contacts::Google::response_body(err.response)
      raise err
    end

    p1.emails << Email.new(:email => local_email)
    p1.save

    @engine.sync
    assert_equal(sync_source.sync_items.conflict.length, 1)
    #sync_source.sync_items.conflict.first.person_remote.emails.collect {|e| puts e.email }

    # now resolve
    sync_source.sync_items.conflict.first.resolve(:remote)
    @engine.sync
    p1.reload
    assert Email.find_by_email(remote_email)
    assert_equal Email.find_by_email(remote_email).person_id, p1.id
    assert_equal p1.emails.length, 1

    # now create an autoresolvable conflict
    c1.reload!
    c1.name = "#{p1.firstname} horst"
    c1.update!
    p1.lastname = 'horst'
    p1.save
    #p1.emails.collect {|e| puts e.email }
    #puts c1.fields('email')
    @engine.sync
  end

  def test_funambol
    @sync_source = SyncSourceFunambol.new(:user => users(:urandom))
    FileUtils.rm_rf(Dir.glob("data/funambol/#{users(:urandom).id}-*"))
    FileUtils.rm_rf(Dir.glob("#{ENV['HOME']}/.config/syncevolution/#{users(:urandom).id}-*"))
    @sync_source.save
    dir = @sync_source.dirname

    @engine = SyncEngine.new(:sync_source => @sync_source)
    @engine.sync
    item_count = @sync_source.sync_items.length

    # move on item
    FileUtils.mv(dir + '0', dir + 'tmp')
    @engine.sync
    assert_equal @sync_source.sync_items.length, item_count - 1

    # simulate add, by moving
    FileUtils.mv(dir + 'tmp', dir + '666')
    @engine.sync
    assert_equal @sync_source.sync_items.length, item_count

    newmail = 'newmail@example.com'
    f = File.open(dir + '666')
    card = f.read
    card[/^EMAIL.*$/] = "EMAIL;TYPE=home:#{newmail}"
    f.close

    f = File.open(dir + '666', 'w')
    f.write(card)
    f.close

    @engine.sync
    assert Email.find_by_email(newmail)
  end
end
