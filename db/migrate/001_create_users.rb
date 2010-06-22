class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users", :force => true do |t|
      t.column :login,                     :string
      t.column :crypted_password,          :string, :limit => 40
      t.column :salt,                      :string, :limit => 40
      t.column :created_at,                :datetime
      t.column :updated_at,                :datetime
      t.column :remember_token,            :string
      t.column :remember_token_expires_at, :datetime
      
      t.integer :person_id  # link to personal data
      
    end
    
     # generate the join table
    create_table "people_users", :id => false do |t|
      t.column "user_id", :integer
      t.column "person_id", :integer
    end
    add_index "people_users", "user_id"
    add_index "people_users", "person_id"
  end

  def self.down
    drop_table "users"
    drop_table "people_users"
  end
end
