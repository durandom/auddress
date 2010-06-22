class Event < ActiveRecord::Base
  belongs_to :user

  #t.string :message
  #t.string :context
  #t.integer :ref
  #t.datetime :created_at

  @@translate = {
    'person_create' => 'created',
    'person_destroy' => 'deleted',
    'person_update' => 'updated',
    'person_merge' => 'merged',
    'duplicate_no_duplicate' => 'are no duplicates',
    'duplicate_merge' => 'merged from duplicates',
    'sync' => ''
  }

  def self.new_with_context(message, context, ref = nil)
    Event.new(
      :message => message,
      :context => context,
      :ref => ref
    )
  end

  def self.person_merge(person)
    self.new_with_context(person.display_name, 'person_merge', person.id)
  end

  def self.person_create(person)
    self.new_with_context(person.display_name, 'person_create', person.id)
  end

  def self.person_destroy(person)
    self.new_with_context(person.display_name, 'person_destroy', person.id)
  end

  def self.person_update(person)
    self.new_with_context(person.display_name, 'person_update', person.id)
  end

  def self.duplicate_no_duplicate(duplicate)
    message = (duplicate.people.collect {|p| p.display_name}).join(', ')
    self.new_with_context(message, 'duplicate_no_duplicate', duplicate.id)
  end

  def self.duplicate_merge(duplicate)
    message = (duplicate.people.collect {|p| p.display_name}).join(', ')
    self.new_with_context(message, 'duplicate_merge', duplicate.id)
  end

  def self.sync(engine)
    self.new_with_context(engine.log.join("\n"), 'sync', engine.sync_source.id)
  end

  def display
    self.message + ' ' + @@translate[self.context]
  end

end
