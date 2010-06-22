class AddDefaultToBookName < ActiveRecord::Migration
  def self.up
    change_column_default(:books, :name, '_default')
  end

  def self.down
    change_column_default(:books, :name, nil)
  end
end
