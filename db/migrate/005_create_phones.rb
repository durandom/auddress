class CreatePhones < ActiveRecord::Migration
  def self.up
    create_table :phones do |t|
      t.string :location
      t.string :capability
      t.string :country
      t.string :area
      t.string :prefix
      t.string :number
      t.string :extension
      
      t.integer :person_id


      t.timestamps
    end
  end

  def self.down
    drop_table :phones
  end
end
