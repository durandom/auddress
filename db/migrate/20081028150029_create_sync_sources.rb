class CreateSyncSources < ActiveRecord::Migration
  def self.up
    create_table :sync_sources do |t|
      t.references :user

      t.string :type # used for single inheritance, we always use a concrete implementation
      t.datetime :last_sync
      t.integer :status

      t.timestamps
    end
  end

  def self.down
    drop_table :sync_sources
  end
end
