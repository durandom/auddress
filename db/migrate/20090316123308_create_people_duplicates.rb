class CreatePeopleDuplicates < ActiveRecord::Migration
  def self.up
    create_table "people_duplicates", :id => false do |t|
      t.column "person_id", :integer
      t.column "duplicate_id", :integer
    end
    add_index "people_duplicates", "person_id"
    add_index "people_duplicates", "duplicate_id"

  end

  def self.down
    drop_table "people_duplicates"
  end
end
