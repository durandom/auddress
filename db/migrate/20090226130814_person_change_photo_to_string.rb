class PersonChangePhotoToString < ActiveRecord::Migration
  def self.up
    change_column :people, :photo, :string
  end

  def self.down
    change_column :people, :photo, :binary, :limit => 1.megabytes
  end
end
