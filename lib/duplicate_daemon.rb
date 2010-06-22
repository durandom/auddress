class DuplicateDaemon

  CHECK_INTERVAL = 30*60  #in seconds

  def self.log(msg)
    puts msg
    Rails::logger.info "SyncDaemon: " + msg
  end

  def self.run
    while true

      # FIXME: just get all user id instead of objects
      #   or make sure we dont create a million objects
      User.find(:all).each do |user|
        uid = user.id

        DuplicateFinder.find_and_assign(user).each do |people|
          log "found dups #{(people.collect{|p| p.id}).join ","} for user #{user.id}"
        end
      end

      sleep_time = CHECK_INTERVAL
      if sleep_time > 0
        log "sleeping #{sleep_time} seconds..."
        sleep sleep_time
      end
    end
  end
end
