class DropPeopleUsers < ActiveRecord::Migration
  def self.up
    # We now organize people in books
    drop_table "people_users"
  end

  def self.down
    # generate the join table
    create_table "people_users", :id => false do |t|
      t.column "user_id", :integer
      t.column "person_id", :integer
    end
    add_index "people_users", "user_id"
    add_index "people_users", "person_id"
  end
end
