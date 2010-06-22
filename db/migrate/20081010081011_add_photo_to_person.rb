class AddPhotoToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :photo, :binary, :limit => 1.megabytes
  end

  def self.down
    remove_column :people, :photo
  end
end
