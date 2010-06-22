class AddFeaturesToSyncItems < ActiveRecord::Migration
  def self.up
    add_column :sync_items, :updated_local, :datetime
    add_column :sync_items, :created_local, :datetime
    add_column :sync_items, :checksum_local, :string

    rename_column :sync_items, :created, :created_remote
    rename_column :sync_items, :updated, :updated_remote
    rename_column :sync_items, :checksum, :checksum_remote
  end

  def self.down
    remove_column :sync_items, :updated_local
    remove_column :sync_items, :created_local
    remove_column :sync_items, :checksum_local

    rename_column :sync_items, :created_remote, :created
    rename_column :sync_items, :updated_remote, :updated
    rename_column :sync_items, :checksum_remote, :checksum
  end
end
