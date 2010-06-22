class ChangeBirthdayToDate < ActiveRecord::Migration
  def self.up
    change_column :people, :birthday, :date
  end

  def self.down
    change_column :people, :birthday, :datetime
  end
end
