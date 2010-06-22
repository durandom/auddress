class RefactorSyncSources < ActiveRecord::Migration
  def self.up
    add_column :sync_sources, :configuration, :string
  end

  def self.down
    remove_column :sync_sources, :configuration
  end
end
