class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations do |t|
      t.integer :user_id
      t.integer :person_id
      t.string :status
      t.string :token

      t.timestamps
    end
  end

  def self.down
    drop_table :invitations
  end
end
