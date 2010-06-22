class AddInvitedUserToInvitations < ActiveRecord::Migration
  def self.up
    add_column :invitations, :invited_user_id, :integer
  end

  def self.down
    remove_column :invitations, :invited_user_id
  end
end
