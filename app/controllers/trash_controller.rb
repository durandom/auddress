class TrashController < ApplicationController
  before_filter :login_required
  before_filter :find_person,
    :only => [:restore, :show]

  def find_person
    @person = Person.find(params[:id])
    # make sure its accessable
    unless @person.user == current_user
      # flash warn here, dont raise exception, user needs to know whats going on
      flash[:warning] = 'You dont have permission to access this Person via URL'
      redirect_to(people_url)
    end
  end
  
  def index
    @people = current_user.trash_book.people
  end

  def show
  end

end
