class CreateEmails < ActiveRecord::Migration
  def self.up
    create_table :emails do |t|
      t.string :location
      t.string :email
      
      t.integer :person_id

      t.timestamps
    end
  end

  def self.down
    drop_table :emails
  end
end
