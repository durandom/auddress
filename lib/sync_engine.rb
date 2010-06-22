class SyncEngine
  attr_accessor :sync_source, :time_frame

  def initialize(*args)
    options = args.extract_options!
    [:sync_source, :time_frame].each do |o|
      if options.has_key?(o)
        self.send("#{o}=", options[o])
      end
    end
    @log = []
  end

  def log(msg = nil)
    if msg
      @log << "#{sync_source.class}: #{msg}"
    else
      @log
    end
  end

  # all items for which no sync item exists
  def new_items
    new_people_ids = (sync_source.user.book.person_ids -
        sync_source.sync_items.collect { |i| i.person.id if i.person } )

    items = []
    sync_source.user.book.people.include_details.find(new_people_ids).each do |p|
      items << SyncItem.new(:person => p)
    end
    #puts pids.join ","
    #puts (items.collect {|i| i.person.display_name}).join ","
    items
  end

  def updated_items
    #return [] unless sync_source.last_sync
    sync_source.sync_items.select do |item|
      #Rails::logger.warn "----#{item.person.display_name}"
      #Rails::logger.warn item.person.updated_at
      #Rails::logger.warn item.updated_local
      #Rails::logger.warn item.person.checksum_deep
      #Rails::logger.warn item.checksum_local
      #Rails::logger.warn item.person.to_txt

      item.person and (
        item.person.updated_at > item.updated_local
        # FIXME: this is just for security reason. Do we really need it?
        #  its a performance killer
        #or ( item.person.updated_at == item.updated_local and
        #    item.person.checksum_deep != item.checksum_local)
      )
    end
    #sync_source.sync_items.include_person_details.find(item_ids)
  end

  def deleted_items
    pids = sync_source.user.book.person_ids
    sync_source.sync_items.select do |item|
      item.person.nil? or not pids.include?(item.person.id)
    end
  end

  def sync
    # we dont want microsecond precision, this might mess up updated_items detection
    #sync_time = Time.at(Time.now.to_i)
    sync_time = Time.now.utc # convert to utc, because ActiveRecord also uses UTC
    SyncSource.transaction do
      Rails::logger.debug("begin sync for #{sync_source.user.login} #{sync_source.class}")
      sync_source.begin_sync

      @ss_new_items     = sync_source.new_items(time_frame)
      @ss_updated_items = sync_source.updated_items(time_frame)
      @ss_deleted_items = sync_source.deleted_items(time_frame)

      @auddress_new_items     = new_items
      @auddress_updated_items = updated_items
      @auddress_deleted_items = deleted_items

      # conflicting items are the intersection of ss_updated_items and auddress
      (@auddress_updated_items & @ss_updated_items).each do |item|
        # Check if it is really a conflict
        # only the syncsource can now if its a real conflict
        #   maybe only some details have changed which cannot be stored in the
        #   foreign format, so we cant update anyway.
        if sync_source.is_conflict_after_convert?(item)
          log "conflict #{item.person.display_name}"
          # remote person gets tagged via lastname
          #  and it also gets updated in auddress
          #  and because we first promote changes from the syncsource to auddress
          #   the changed lastname is also synced back to the syncsource
          #   so, this is a bit hacky, as we depend on this order
          item.person_remote.lastname += " (#{sync_source.name})"
          item.person_remote.save

          # we also add the person from auddress as a new person to auddress
          # and promtote it to the syncsource
          new_person = item.person.clone_deep
          sync_source.user.book.people << new_person
          @auddress_new_items << SyncItem.new(:person => new_person)

          # and also mark those as duplicates
          dup = Duplicate.new(:user => sync_source.user)
          dup.person_ids = [item.person.id, new_person.id]
          dup.save
        else
          # no conflict, so update meta data
          log "auto resolve conflict #{item.person.display_name}"
          # remove this item from updated_items array to cancel update of item
          @ss_updated_items.delete(item)
          @auddress_updated_items.delete(item)
          update_meta_and_save(item)
        end
      end

      # remove updated items from deleted arrays. this means that a deletion gets
      #  rolled back and the updates are promoted
      (@ss_deleted_items & @auddress_updated_items).each do |item|
        @auddress_new_items << item
        @ss_deleted_items.delete(item)
        @auddress_updated_items.delete(item)
      end
      (@auddress_deleted_items & @ss_updated_items).each do |item|
        @ss_new_items << item
        @auddress_deleted_items.delete(item)
        @ss_updated_items.delete(item)
      end
    
      # First promote everything from the syncsource to auddress
      #  DONT CHANGE THIS ORDER, we rely on it with conflicts. See above
      @ss_new_items.each do |item|
        log "adding #{item.person_remote.display_name} to auddress"
        # move the remote person to the local book, this also saves the person
        sync_source.user.book.people << item.person_remote
        item.person = item.person_remote
        item.person_remote = nil
        item.created_local = item.person.created_at
        if sync_source.respond_to?(:item_created_at)
          item.created_remote = sync_source.item_created_at(item)
        end
        #sync_source.sync_items << item if item.new_record?
        item.sync_source = sync_source
        update_meta_and_save(item)
      end

      # FIXME: can we speedup deletion by passing an array of ids to delete?
      @ss_deleted_items.each do |item|
        # make sure the person still exists in auddress
        unless item.person
          log "syncitem #{item.id} already deleted from auddress"
          sync_source.sync_items.delete(item)
          next
        end
        log "deleting #{item.person.display_name} from auddress"
        #sync_source.user.book.remove(item.person)
        # FIXME: move the item to a Trash?
        # FIXME: Ticket #157
        # make sure we dont delete ourselves and linked people
        if item.person != sync_source.user.person and item.person.link.nil?
          item.person.destroy
        else
          log "#{item.person.display_name} deleted in #{sync_source.class}, re-adding on next run"
        end
        sync_source.sync_items.delete(item)
      end

      @ss_updated_items.each do |item|
        log "updating #{item.person_remote.display_name} in auddress"
        item.person.update_with!(item.person_remote, sync_source.filter)
        item.person.save
        # remove person_remote
        item.person_remote.destroy unless item.person_remote.new_record?
        item.person_remote = nil
        update_meta_and_save(item)
      end

      # Now everything from auddress to the syncsource
      @auddress_new_items.each do |item|
        if sync_source.add_item!(item)
          #sync_source.sync_items << item if item.new_record?
          item.sync_source = sync_source
          update_meta_and_save(item)
          log "adding #{item.person.display_name} to #{sync_source.class}"
        else
          log "failed adding #{item.person.display_name} to #{sync_source.class}"
        end
      end

      @auddress_deleted_items.each do |item|
        log "deleting #{item.key} from #{sync_source.class}"
        sync_source.delete_item(item)
        sync_source.sync_items.delete(item)
      end

      @auddress_updated_items.each do |item|
        if sync_source.update_item!(item)
          # why cannot update fronze
          update_meta_and_save(item)
          log "updating #{item.person.display_name} in #{sync_source.class}"
        else
          item.conflict
          item.save
          log "failed updating #{item.person.display_name} in #{sync_source.class}"
        end
      end

      sync_source.last_sync = sync_time
      sync_source.save

      sync_source.end_sync
    end
  end

  def update_meta_and_save(item, status = :sync)
    # FIXME: cant update frozen?
    item.checksum_remote = sync_source.checksum(item)
    item.checksum_local = item.person.checksum_deep
    item.updated_local = item.person.updated_at
    if sync_source.respond_to?(:item_updated_at)
      item.updated_remote = sync_source.item_updated_at(item)
    end
    item.send(status)
    item.save
  end

  # checks if this item is a conflict which cannot be resolved
  def is_real_conflict?(item)
    # remove this item from updated_items array to cancel update of item
    @ss_updated_items.delete(item)
    @auddress_updated_items.delete(item)
    # only the syncsource can now if its a real conflict
    #   maybe only some details have changed which cannot be stored in the
    #   foreign format, so we cant update anyway.
    if sync_source.is_conflict_after_convert?(item)
      item.person_remote.save # for later presentation of conflict
      update_meta_and_save(item, :conflict)
      true
    else
      # no conflict, so update meta data
      update_meta_and_save(item)
      false
    end    
  end

end