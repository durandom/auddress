# FIXME: destroy empty duplicate groups, garbage collect

class Duplicate < ActiveRecord::Base
  has_many :people
  belongs_to :user

  # no_duplicate boolean
  # user

  named_scope :by_user, lambda { |user|
    { :conditions => {
        :no_duplicate => false,
        :user_id => user.is_a?(User) ? user.id : user
      } } }

  # finds and returns duplicates as an array of possible duplicates as Person
  # objects: duplicates = [ [Person1, Person2], [Person5,Person6,Person7] ]
  def self.scan(candidates)
    # make sure we have an array, if we would have User.book.people
    # it would be an association_proxy and then .delete would do something
    # very different
    candidates = candidates.to_a

    duplicates = []
    # we loop as long as we have some candidates
    # 1. take the first person
    while person = candidates.shift do
      found_dups = [person]
      # now compare it all remaining candidates
      candidates.each_with_index do |candidate, index|
        # ignore those which are already dups
        # FIXME: improve this
        #(person.duplicates + candidate.duplicates).uniq.each do |dup|
        person.duplicates.each do |dup|
          if dup.people.member?(person) and dup.people.member?(candidate)
            candidates[index] = nil
            break
          end
        end

        if candidates[index] and duplicate?(person, candidate)
          #puts "gotcha #{person.id} #{candidate.id}"
          # put into duplicates
          found_dups << candidate
          # remove from candidates
          candidates[index] = nil
        end
      end
      # add to duplicates if we found more than one
      # (one would be only the compared person)
      duplicates << found_dups if found_dups.length > 1
      # remove all nil elements
      candidates.delete(nil)
    end

    return duplicates
  end

  def self.scan_and_create(candidates, user)
    self.scan(candidates).each do |people|
      dup = Duplicate.new(:user => user)
      dup.people = people
      dup.save
    end
  end

  def event_no_duplicate
    self.user.events << Event.duplicate_no_duplicate(self)
  end

  def event_merge
    self.user.events << Event.duplicate_merge(self)
  end


end
