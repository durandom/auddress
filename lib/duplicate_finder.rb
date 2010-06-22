class DuplicateFinder
  
  # finds and returns duplicates as a hash of objects
  # { 1 => [ 2, 3 ], 2 => [1,3], 3 => [1,2] }
  def self.find(candidates)

    duplicates = {}
    c_size = candidates.size - 1

    candidates.each_with_index do |person, index|
      # now compare it all remaining candidates
      candidates.last(c_size - index).each do |candidate|
        # ignore those which are already dups or false dups
        next if (person.duplicates + person.false_duplicates).member?(candidate)
        next if (candidate.duplicates + candidate.false_duplicates).member?(person)

        if person.duplicate?(candidate)
          #puts "gotcha #{person.id} #{candidate.id}"
          # put into duplicates
          duplicates[person] ||= []
          duplicates[person] << candidate
        end
      end
    end

    return duplicates
  end

  def self.find_and_create_model(candidates, user)
    self.find(candidates).each do |people|
      person = people.shift
      person.duplicates << people
    end
  end

  def self.find_and_assign_off(user)
    self.find(user.book.people.include_duplicates.include_false_duplicates).each do |people|
      # every duplicate group member gets itself assigned as a duplicate
      people.each_with_index do |person, index|
        people.last(people.size - index - 1).each do |dup|
          unless person.duplicates.member?(dup) or
              person.false_duplicates.member?(dup)
            person.duplicates << dup
          end
          unless dup.duplicates.member?(person) or
              dup.false_duplicates.member?(person)
            dup.duplicates << person
          end
        end
      end
    end
  end

  def self.find_and_assign(user)
    self.find(user.book.people.include_duplicates.include_false_duplicates).each_pair do |person, duplicates|
      duplicates.each do |dup|
        dup.duplicates << person unless dup.duplicates.member?(person)
        person.duplicates << dup unless person.duplicates.member?(dup)
      end
    end
  end


  def self.clear_all(user)
    user.people.each do |p|
      p.duplicates.clear
      p.false_duplicates.clear
    end
  end
end
