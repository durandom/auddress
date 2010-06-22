class CreateSyncItems < ActiveRecord::Migration
  def self.up
    create_table :sync_items do |t|
      t.references :person
      t.references :sync_source
      t.string :key
      t.datetime :updated
      t.datetime :created
      t.string :checksum
      t.integer :status

      t.timestamps
    end
  end

  def self.down
    drop_table :sync_items
  end
end
