class DropUploads < ActiveRecord::Migration
  def self.up
    drop_table :uploads
  end

  def self.down
    create_table :uploads do |t|
      t.string :file
      t.integer :size
      t.string :content_type

      t.integer :user_id

      t.timestamps
    end

  end
end
