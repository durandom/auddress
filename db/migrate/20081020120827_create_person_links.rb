class CreatePersonLinks < ActiveRecord::Migration
  def self.up
    create_table :person_links do |t|
      t.references :person
      t.references :source_person
      t.timestamps
    end
    
#    create_table "emails_person_links", :id => false do |t|
#      t.column "email_id", :integer
#      t.column "person_link_id", :integer
#    end
    
#    add_index "emails_person_links", "email_id"
#    add_index "emails_person_links", "person_link_id"
  end

  def self.down
    drop_table :person_links
#    drop_table "emails_person_links"
  end
end
