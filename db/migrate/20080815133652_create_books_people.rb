class CreateBooksPeople < ActiveRecord::Migration
  def self.up
    # generate the join table
    create_table "books_people", :id => false do |t|
      t.column "person_id", :integer
      t.column "book_id", :integer
    end
    add_index "books_people", "book_id"
    add_index "books_people", "person_id"

  end

  def self.down
    drop_table "books_people"
  end
end
