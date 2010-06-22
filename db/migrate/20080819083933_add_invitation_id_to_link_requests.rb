class AddInvitationIdToLinkRequests < ActiveRecord::Migration
  def self.up
    add_column :link_requests, :invitation_id, :integer
  end

  def self.down
    remove_column :link_requests, :invitation_id
  end
end
