# never use this directly
# use SyncSourceVcard e.g.

class SyncSource < ActiveRecord::Base
  belongs_to :user
  has_many :sync_items, :include => :person, :dependent => :destroy do
    def conflict
      self.select {|i| i.conflict? }
    end
    def sync
      self.select {|i| i.sync? }
    end
    def status(status)
      status = status.to_s
      self.select {|i| i.send(status+'?') }
    end
    def keys
      @sync_item_keys ||= self.collect {|i| i.key }
    end
  end
  # attr :last_sync (datetime)
  # attr :type (for single inheritance, stores concrete implementation, e.g SyncSourceVcard)
  # attr :configuration => serialized config, or just a token

  validates_presence_of :user

  # in case we sync multiple times without destroying the object
  # this makes sure that sync_items are not cached
  after_save :reset

  def reset
    sync_items.reset
  end

  def name
    self.class.to_s.gsub(/SyncSource/, '')
  end

  def begin_sync
  end

  def end_sync
  end

  def update_item!(item)
  end

  def add_item!(item)
  end

  def delete_item(item)
  end

  def updated_items(time_frame)
  end

  def new_items(time_frame)
  end

  def deleted_items(time_frame)
  end

  def filter
  end
 
  # returns a checksum, which is updated for the syncitem after every save
  def checksum(item)
  end

  # returns person in a syncsource specific object
  def person_to_obj(person)
  end

  def is_conflict_after_convert?(item)
    # convert local to remote
    person_c = Convert.to_person(person_to_obj(item.person))
    not person_c.alike?(item.person_remote)
  end

end
