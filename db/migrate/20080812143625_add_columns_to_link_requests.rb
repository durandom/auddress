class AddColumnsToLinkRequests < ActiveRecord::Migration
  def self.up
   change_table :link_requests do |t|
      t.integer :requested_user_id
    end
  end

  def self.down
   change_table :link_requests do |t|
      t.remove :requested_user_id
    end
  end
end
