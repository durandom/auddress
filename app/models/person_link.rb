class PersonLink < ActiveRecord::Base
  belongs_to :person #destination, where we link into
  belongs_to :source_person, :class_name => 'Person'

  # Proxy all details to source_person
#  (Person.details +
#   Person.collection_details +
#   [:display_name]).each  do |detail|
#    code = %Q{
#      def #{detail}
#        source_person.#{detail}
#      end
#    }
#    class_eval(code)
#  end

  (Person.details + Person.collection_details).each  do |detail|
    delegate detail, :to => :source_person
  end

  # FIXME: make sure only user.person is the source_person ?
  #   but do we really need it? or might it be a feature for further use?
  #   think sharing adressbook entries
end
