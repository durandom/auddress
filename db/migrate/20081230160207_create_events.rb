class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.string :message
      t.string :context
      t.integer :ref
      t.references :user
      t.datetime :when
    end
  end

  def self.down
    drop_table :events
  end
end
