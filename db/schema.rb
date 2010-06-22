# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090316133900) do

  create_table "addresses", :force => true do |t|
    t.string   "location",   :default => ""
    t.string   "street",     :default => ""
    t.string   "number",     :default => ""
    t.string   "zip",        :default => ""
    t.string   "city",       :default => ""
    t.string   "country",    :default => ""
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "books", :force => true do |t|
    t.string   "name",       :default => "_default"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "books_people", :id => false, :force => true do |t|
    t.integer "person_id"
    t.integer "book_id"
  end

  add_index "books_people", ["book_id"], :name => "index_books_people_on_book_id"
  add_index "books_people", ["person_id"], :name => "index_books_people_on_person_id"

  create_table "config", :force => true do |t|
    t.integer "associated_id"
    t.string  "associated_type"
    t.string  "namespace"
    t.string  "key",             :limit => 40, :null => false
    t.string  "value"
  end

  create_table "duplicates", :force => true do |t|
    t.integer  "user_id"
    t.boolean  "no_duplicate", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "duplicates_people", :id => false, :force => true do |t|
    t.integer "person_id"
    t.integer "duplicate_id"
  end

  create_table "emails", :force => true do |t|
    t.string   "location",   :default => ""
    t.string   "email",      :default => ""
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "events", :force => true do |t|
    t.string   "message"
    t.string   "context"
    t.integer  "ref"
    t.integer  "user_id"
    t.datetime "created_at"
  end

  create_table "invitations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "person_id"
    t.string   "status"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "invited_user_id"
  end

  create_table "link_requests", :force => true do |t|
    t.integer  "user_id"
    t.integer  "person_id"
    t.string   "email"
    t.string   "token"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "requested_user_id"
    t.integer  "invitation_id"
  end

  create_table "people", :force => true do |t|
    t.string   "firstname",    :default => ""
    t.string   "lastname",     :default => ""
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "organization", :default => ""
    t.date     "birthday"
    t.string   "title",        :default => ""
    t.string   "nickname",     :default => ""
    t.string   "url",          :default => ""
    t.string   "photo",        :default => ""
  end

  create_table "people_duplicates", :id => false, :force => true do |t|
    t.integer "person_id"
    t.integer "duplicate_id"
  end

  add_index "people_duplicates", ["duplicate_id"], :name => "index_people_duplicates_on_duplicate_id"
  add_index "people_duplicates", ["person_id"], :name => "index_people_duplicates_on_person_id"

  create_table "people_false_duplicates", :id => false, :force => true do |t|
    t.integer "person_id"
    t.integer "duplicate_id"
  end

  add_index "people_false_duplicates", ["duplicate_id"], :name => "index_people_false_duplicates_on_duplicate_id"
  add_index "people_false_duplicates", ["person_id"], :name => "index_people_false_duplicates_on_person_id"

  create_table "person_links", :force => true do |t|
    t.integer  "person_id"
    t.integer  "source_person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "phones", :force => true do |t|
    t.string   "location",   :default => ""
    t.string   "capability", :default => ""
    t.string   "country",    :default => ""
    t.string   "area",       :default => ""
    t.string   "prefix",     :default => ""
    t.string   "number",     :default => ""
    t.string   "extension",  :default => ""
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string "name"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "sync_items", :force => true do |t|
    t.integer  "person_id"
    t.integer  "sync_source_id"
    t.string   "key"
    t.datetime "updated_remote"
    t.datetime "created_remote"
    t.string   "checksum_remote"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "person_remote_id"
    t.datetime "updated_local"
    t.datetime "created_local"
    t.string   "checksum_local"
  end

  create_table "sync_sources", :force => true do |t|
    t.integer  "user_id"
    t.string   "type"
    t.datetime "last_sync"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "configuration"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.integer  "person_id"
    t.datetime "tocaccepted"
  end

end
