class AddTitleNicknameUrlToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :title, :string
    add_column :people, :nickname, :string
    add_column :people, :url, :string
  end

  def self.down
    remove_column :people, :url
    remove_column :people, :nickname
    remove_column :people, :title
  end
end
