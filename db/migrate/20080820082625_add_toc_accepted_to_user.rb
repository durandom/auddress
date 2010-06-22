class AddTocAcceptedToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :tocaccepted, :datetime
  end

  def self.down
    remove_column :users, :tocaccepted
  end
end
