class RenameImportsToUploads < ActiveRecord::Migration
  def self.up
    rename_table(:imports, :uploads)
  end

  def self.down
    rename_table(:uploads, :imports)
  end
end
