class CreateDuplicates < ActiveRecord::Migration
  def self.up
    # generate the join table
    create_table "duplicates_people", :id => false do |t|
      t.column "person_id", :integer
      t.column "duplicate_id", :integer
    end

    create_table :duplicates do |t|
      t.references :user
      t.boolean :no_duplicate, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :duplicates
    drop_table :duplicates_people
  end
end
