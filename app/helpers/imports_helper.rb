module ImportsHelper
  def mark_contact(ids)
    '"' + ids.collect {|id| "$('person_#{id}').addClassName('marked')" }.join(';') + '"'
  end 

  def un_mark_contact(ids)
    '"' + ids.collect {|id| "$('person_#{id}').removeClassName('marked')" }.join(';') + '"'
  end 
end
