class RenameConflictPersonInSyncItems < ActiveRecord::Migration
  def self.up
    rename_column :sync_items, :conflict_person_id, :person_remote_id
  end

  def self.down
    rename_column :sync_items, :person_remote_id, :conflict_person_id
  end
end
