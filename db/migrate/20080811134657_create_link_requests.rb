class CreateLinkRequests < ActiveRecord::Migration
  def self.up
    create_table :link_requests do |t|      
      t.integer :user_id
      t.integer :person_id

      t.string :email

      t.string :token
      t.string :status

      t.timestamps
    end
  end

  def self.down
    drop_table :link_requests
  end
end
