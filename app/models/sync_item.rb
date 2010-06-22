class SyncItem < ActiveRecord::Base
  belongs_to :sync_source
  belongs_to :person
  belongs_to :person_remote, :class_name => 'Person'

  # :key      => store for remote id
  # :checksum_remote => checksum of remote item
  # :checksum_local => checksum of remote item
  # :updated_remote  => remote update date
  # :created_remote  => remote creation date
  # :updated_local  => local update date
  # :created_local  => local creation date

  # :status   => see below
  code = 0
  [:sync, :conflict, :resolve_local, :resolve_remote].each do |s|
    class_eval(<<-EOS)
       def #{s}?
          self.status == #{code}
       end
       def #{s}
          self.status = #{code}
          true
       end
    EOS
    code += 1
  end

  named_scope :include_person_details, 
    :include => { :person => [* (Person.collection_details + [:link]) ] }

  def resolve(action)
    action = action.to_sym
    #self.sync_source = sync_item.sync_source unless sync_source

    case action
    when :local
      self.resolve_local
    when :remote
      self.resolve_remote
    when :merge
      self.person_remote.merge!(self.person)
      self.resolve_remote
    else
      raise "no such resolve action #{action}"
    end
    self.save
  end

end
