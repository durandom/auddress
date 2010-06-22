class AllStringDefaultsEmpty < ActiveRecord::Migration
  def self.up
    change_table :addresses do |t|
      t.change_default   "location", ''
      t.change_default   "street", ''
      t.change_default   "number", ''
      t.change_default   "zip", ''
      t.change_default   "city", ''
      t.change_default   "country", ''
    end

    change_table "emails" do |t|
      t.change_default   "location", ''
      t.change_default   "email", ''
    end

    change_table "people" do |t|
      t.change_default   "firstname", ''
      t.change_default   "lastname", ''
      t.change_default   "organization", ''
      t.change_default   "title", ''
      t.change_default   "nickname", ''
      t.change_default   "url", ''
    end

    change_table "phones" do |t|
      t.change_default   "location", ''
      t.change_default   "capability", ''
      t.change_default   "country", ''
      t.change_default   "area", ''
      t.change_default   "prefix", ''
      t.change_default   "number", ''
      t.change_default   "extension", ''
    end
  end

  def self.down
  end
end
