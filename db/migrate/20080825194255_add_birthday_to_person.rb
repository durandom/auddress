class AddBirthdayToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :birthday, :datetime
  end

  def self.down
    remove_column :people, :birthday
  end
end
