class SyncDaemon

  SYNC_INTERVAL = 30*60  #in seconds

  def self.log(msg)
    puts msg
    Rails::logger.info "SyncDaemon: " + msg
  end

  def self.run(interval = SYNC_INTERVAL)
    while true
      oldest_sync = Time.now.utc

      # FIXME: just get all user id instead of objects
      #   or make sure we dont create a million objects
      User.find(:all).each do |u|        
        uid = u.id

        last_sync_count = 0
        sync_runs = 0 # make sure we dont loop forever on the same guy
        begin
          # sync until the log is empty
          log = []
          synced = false
          SyncSource.find_all_by_user_id(uid).each do |ss|
            if ss.last_sync.nil? or
                (Time.now.utc - ss.last_sync) > interval or
                last_sync_count > 0
              engine = SyncEngine.new(:sync_source => ss)
              engine.sync
              log.concat(engine.log)
              synced = true
              sync_runs += 1
              if ss.class == SyncSourceVcard and not engine.log.empty?
                backup = Backup.new(ss)
                backup.commit(engine.log.join("\n"))
              end
              unless engine.log.empty?
                u.events << Event.sync(engine)
              end

            elsif ss.last_sync < oldest_sync
              oldest_sync = ss.last_sync
            end
          end
          last_sync_count = log.length
          log "synced #{u.login}\n" + log.join("\n") if synced
        end while last_sync_count > 0 and sync_runs <= 3
      end
      
      sleep_time = (oldest_sync + interval) - Time.now.utc
      if sleep_time > 0
        log "sleeping #{sleep_time} seconds..."
        sleep sleep_time
      end
    end
  end

end
