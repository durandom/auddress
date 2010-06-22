class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.string :location
      t.string :street
      t.string :number
      t.string :zip
      t.string :city
      t.string :country
      
      t.integer :person_id

      t.timestamps
    end
    
    
  end

  def self.down
    drop_table :addresses
  end
end
