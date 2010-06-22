module PeopleUtils
  def build_people_struct(ids)
    # FIXME: ensure access rights to people ids
    people = {}
    ids.each do |person_id|
      person = Person.find(person_id)
      person.details.each do |detail|
        # initialise the array, the empty array will be filled with this
        # persons id at the end of the first iteration
        people[detail] ||= {person => []}
        # now loop over every unique person
        found = false
        people[detail].each_key do |p|
          # if both details are the same
          # (only compare stringwise, this catches nil != "")
          if person.send(detail).to_s == p.send(detail).to_s
            # add the person.id to the array of ids
            people[detail][p] << person.id
            found = true
            break
          end
        end
        # nothing found? and not empty?
        # add it to the array of unique persons
        people[detail][person] = [person.id] if not found and not person.send(detail).to_s.empty?
      end

      # do the same with collection_details
      person.collection_details.each do |detail|
        person.send(detail).with_link.each do |detail_object|
          # initialise the array, the empty array will be filled with this
          # persons id at the end of the first iteration
          # create a clone of the detail, so we have a new record and dont work on existing details
          detail_object = detail_object.clone
          people[detail] ||= {detail_object => []}
          # now loop over every unique detail
          found = false
          people[detail].each_key do |d|
            # if both details are the same
            if detail_object.same?(d)
              # add the person.id to the array of ids
              people[detail][d] << person.id
              found = true
              break
            end
          end
          # nothing found?
          # add it to the array of unique persons
          people[detail][detail_object] = [person.id] if not found
        end
        people[detail] ||= {} # in case no detail was found, so we have an empty hash
      end
    end
    # merge firstname and lastname
    people[:name] = people[:firstname]
    people[:lastname].each do |k,v|
      if people[:name].member?(k)
        people[:name][k] |= v
      else
        people[:name][k] = v
      end
    end
    return people
  end
 
end
