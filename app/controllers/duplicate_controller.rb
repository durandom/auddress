class DuplicateController < ApplicationController

  def index
    if (params[:id])
      @person = find_person
    else
      @person = current_user.book.people.duplicates.find(:first)
    end

    unless @person
      # FIXME: show a message?
      flash[:notice] = 'You have no duplicates'
      redirect_to(people_url)
    end
  end

  def merge
  end

  def unique
    person = find_person
    duplicate = find_person(params[:duplicate])

    # This is the list of displayed duplicates excluding the one clicked as no duplicate
    dups = current_user.people.find(person.duplicate_ids + [person.id] - [duplicate.id])

    dups.each do |dup|
      # remove the clicked one and add it to false dups
      dup.duplicates.delete(duplicate) if dup.duplicates.member?(duplicate)
      dup.false_duplicates << duplicate unless dup.false_duplicates.member?(duplicate)
      # add this one to the clicked one
      duplicate.duplicates.delete(dup) if duplicate.duplicates.member?(dup)
      duplicate.false_duplicates << dup unless duplicate.false_duplicates.member?(dup)
    end

    # Make sure there are dups to display
    if person.id == duplicate.id
      @person = dups.first
    else
      @person = person
    end

    if @person.duplicates.empty?
      flash[:warning] = 'No more duplicates'
      redirect_to(people_url)
    else
      render :action => :index
    end
  end

  # starts scan for duplicates, only for debugging purposes
  def find
    dups = DuplicateFinder.find_and_assign(current_user)
    flash[:notice] = "Found #{dups.size} duplicates"
    redirect_to(user_url(current_user))
  end

  private
  def find_person(id = params[:id])
    #person = Person.include_duplicates.include_false_duplicates.find(id)
    person = Person.find(id)
    # make sure its accessable
    if person.user != current_user
      # FIXME: do we store people elsewhere than default book?
      #unless current_user.book.exists?(@person)
      # flash warn here, dont raise exception, user needs to know whats going on
      flash[:warning] = 'You dont have permission to access this Person via URL'
      redirect_to(people_url)
      #end
    end
    person
  end

end
