class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.string :firstname
      t.string :lastname

      t.integer :owner_id # the owner of this person
      
      t.timestamps
    end
  end

  def self.down
    drop_table :people
  end
end
