class AddOrgToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :organization, :string
  end

  def self.down
    remove_column :people, :organization
  end
end
