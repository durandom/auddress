class PersonChangePhotoDefaultToEmptyString < ActiveRecord::Migration
  def self.up
    change_table "people" do |t|
      t.change_default   "photo", ''
    end
  end

  def self.down
  end
end
