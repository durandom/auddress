class RenameOwnerToUserInPeople < ActiveRecord::Migration
  def self.up
    rename_column :people, :owner_id, :user_id
  end

  def self.down
    rename_column :people, :user_id, :owner_id
  end
end
