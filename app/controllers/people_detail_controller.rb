class PeopleDetailController < ApplicationController
  
  
  before_filter :login_required
  before_filter :find_person
  before_filter :find_detail, 
    :only => [               :show, :edit, :update, :destroy]
  before_filter :detail_belongs_to_current_user, 
    :only => [                      :edit, :update, :destroy]
  before_filter :person_belongs_to_current_user, 
    :only => [:new, :create]

  def initialize
    @detail = "replace_by_detail_name_eg_phone"
  end
  
  def find_person
    @person = Person.find(params[:person_id])
    # make sure its accessable
    # FIXME maybe its enough to have the current_user as user
    unless @person.user == current_user
      # FIXME this throws an exception
      # put this into a try / catch block?
      raise Exception, "have to search in all books for this user"
      #@person.users.find(current_user.id)
    end
  end
  
  def find_detail
    # sets @phone = @person.phones.find(params[:id])
    @my_detail = @person.method(@detail.pluralize).call.find(params[:id])
    self.instance_variable_set("@#{@detail}", @my_detail)
  end
  
  def detail_belongs_to_current_user
    #unless self.instance_variable_get("@#{@detail}").person.user == current_user
    unless @my_detail.person.user == current_user
      raise Exception, "You are not allowed to do this" 
    end    
  end
  
  def person_belongs_to_current_user
    unless @person.user == current_user
      raise Exception, "You are not allowed to do this" 
    end
  end

  def index
    #@phones = @person.phones
    @details = @person.method(@detail.pluralize).call
    self.instance_variable_set("@#{@detail.pluralize}", @details)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @details }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @my_detail }
    end
  end

  def new
    @my_detail = @detail.camelize.constantize.new
    self.instance_variable_set("@#{@detail}", @my_detail)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @my_detail }
    end
  end

  # GET /phones/1/edit
  def edit
  end

  # POST /phones
  # POST /phones.xml
  def create
    @my_detail = @detail.camelize.constantize.new(params[@detail])
    self.instance_variable_set("@#{@detail}", @my_detail)

    @my_detail.person = @person

    respond_to do |format|
      if @my_detail.save
        flash[:notice] = @detail.humanize + ' was successfully created.'
        format.html { redirect_to([ @person, @my_detail]) }
        #format.xml  { render :xml => @my_detail, :status => :created, :location => @phones }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @my_detail.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /phones/1
  # PUT /phones/1.xml
  def update
    respond_to do |format|
      if @my_detail.update_attributes(params[@detail])
        flash[:notice] = @detail.humanize + ' was successfully updated.'
        format.html { redirect_to([ @person, @my_detail]) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @my_detail.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /phones/1
  # DELETE /phones/1.xml
  def destroy
    @my_detail.destroy
    my_details_url = eval("person_#{@detail.pluralize}_url")
    

    respond_to do |format|
      format.html { redirect_to(my_details_url) }
      format.xml  { head :ok }
    end
  end
end
