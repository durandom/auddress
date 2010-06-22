class DropImports < ActiveRecord::Migration
  def self.up
    drop_table :imports
  end

  def self.down
    create_table :imports do |t|
      t.integer :user_id

      t.timestamps
    end
  end
end
