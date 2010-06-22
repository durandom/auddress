class AddConflictPersonToSyncItems < ActiveRecord::Migration
  def self.up
    add_column :sync_items, :conflict_person_id, :integer
  end

  def self.down
    remove_column :sync_items, :conflict_person_id
  end
end
