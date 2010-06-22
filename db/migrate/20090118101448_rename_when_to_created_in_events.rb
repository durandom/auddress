class RenameWhenToCreatedInEvents < ActiveRecord::Migration
  def self.up
    rename_column :events, :when, :created_at
  end

  def self.down
    rename_column :events, :created_at, :when
  end
end
