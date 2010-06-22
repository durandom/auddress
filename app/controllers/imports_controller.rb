class ImportsController < ApplicationController

  include PeopleUtils
  
  before_filter :login_required
  before_filter :find_import, 
    :only => [:show, :import]

  def find_import
    @import = Import.find(params[:id])
    unless @import.user == current_user
      flash[:warning] = 'You dont have permission to this import'
      redirect_to(root_url)
    end
  end
  
  # GET /imports
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /imports/1
  def show
    # find duplicates of import book and user book
    duplicates = Duplicates.new(current_user.book.people.dup +
        current_user.import_book.people.dup - [current_user.person])
    @duplicates = duplicates.find_duplicates

    # save those who are not duplicates
    import_ids = current_user.import_book.person_ids
    @duplicates.each do |dup_array|
      dup_array.each do |dup|
        import_ids.delete(dup.id)
      end
    end
    @import.move_to_book(import_ids)

    respond_to do |format|
      flash[:notice] = _('%s contacts have been imported ') % import_ids.length
      if @duplicates.length > 0
        format.html # show.html.erb
      else
        format.html { redirect_to(people_url) }
      end
    end
  end

  # GET /imports/vcard
  def vcard
    respond_to do |format|
      format.html # new.html.erb
    end
  end


  # POST /imports
  def create_vcard
    # create the specialized import
    @import = ImportVcard.new
    @import.user = current_user
    
    # create/save the uploaded file
    upload_file = params[:file]
    @import.file = upload_file

    respond_to do |format|
      if upload_file && @import.import
        flash[:notice] = _('%s contacts have been imported ') % @import.count        
        #format.html { redirect_to(:action => "show", :id => @import.id) }
        #format.html { render :action => "show" }
      else
        flash[:notice] = "nothing new here"
        #format.html { render :action => "vcard" }
      end
      format.html { redirect_to(people_url) }
    end
  end

  def edit_many
    @people = nil
    @people_ids = params[:people]
    unless @people_ids.nil? or params[:people].empty?
      @people = build_people_struct(params[:people])
    end

    render :layout => false
  end

  def edit_import_merge
    @people = nil
    unless params[:people].nil? or params[:people].empty?
      @people = build_people_struct(params[:people])
    end
    respond_to do |format|
      if @people
        # propagate the duplicate param
        @duplicate = params[:duplicate] if params[:duplicate]
        format.html { render :partial => 'form_many',
          :locals => { :people => @people,
            :people_ids => params[:people],
            :hide_controls => true,
            :action => 'import_merge'
          }
        }
      else
        format.html { render :partial => 'merge' }
      end
    end
  end

  def import_merge
    if params[:no_duplicate]
      duplicate = Duplicate.find(params[:duplicate_id].to_i)
      unless duplicate.user == current_user
        flash[:warning] = 'Its not your dup!'
        render :update do |page|
          page.redirect_to people_url
        end
        return
      end

      if params[:no_duplicate] == 'true'
        duplicate.no_duplicate = true
        duplicate.save
        duplicate.event_no_duplicate
        render :update do |page|
          page.redirect_to :controller => 'duplicate'
        end
        return
      else
        duplicate.event_merge
        duplicate.destroy
      end
    end

    @person = Person.new(params[:person])
    @person.user = current_user

    # FIXME: merging should not destroy all people but update one
    if current_user.book.add(@person)
      @person.event_create
      # we come from a merge
      # delete all people that originally made up this new person
      @delete_people_ids = []
      params[:people].each do |id|
        person = Person.find(id)
        # only destroy people we own and dont destroy ourself
        if person.user == current_user and person != current_user.person
          @delete_people_ids << dom_id(person) # remove these ids from the list
          person.event_destroy
          person.destroy
        end
      end
      flash[:notice] = 'Person successfully merged.'
      @hide_controls = true

      if params[:duplicate_id]
        render :update do
          |page| page.redirect_to :controller => 'duplicate'
        end
      else
        render :action => :show_import_merge
      end
    else
      render :action => :edit_many_error
    end
  end
#  # Copies selected ids to the users book
#  def import
#    respond_to do |format|
#      if @import.move_to_book(params[:import][:import_ids])
#        # now delete the import?
#        @import.clear!
#        flash[:notice] = _('imported %s contacts') % params[:import][:import_ids].length
#        format.html { redirect_to :action => 'index', :controller => 'people' }
#      else
#        format.html { render :action => 'vcard' }
#      end
#    end
#  end
    
end
