class PeopleController < ApplicationController

  include PeopleUtils

  before_filter :login_required
  before_filter :find_person, 
    :only => [:edit, :update, :destroy, :create_photo, :show]

  #in_place_edit_for :person, :firstname

  caches_page :photo
  

  # GET /people
  def index
    # FIXME: dont use paginate, use find_each
    # http://guides.rubyonrails.org/active_record_querying.html#retrieving-multiple-objects-in-batches
    @page = params[:page] || 1
    # FIXME: dont re-perform the search every time
    if f=params[:filter]
      f.upcase!
      @people = current_user.book.people.select do |person|
        person.lastname.first.upcase == f
      end.paginate(:page =>  @page)
    elsif q=params[:query]
      # FIXME: this search is the opposite of performant
      q = q.upcase
      @people = current_user.book.people.include_details.select do |person|
        person.to_txt_deep.upcase[q]
      end.paginate(:page =>  @page)
    else
      @people = current_user.book.people.include_duplicates.paginate(:page =>  @page)
    end


    respond_to do |format|
      format.html {}
      format.js do
        # determine contact that was last
        #@page = params[:page].to_i + 1
        #@people = people_found.paginate(:page =>  @page)

        if @people.empty?
          render :text => '<a id="complete"/>';
        else
          render :partial => 'list_item', :collection => @people, :locals => {:page => @page}
        end
      end
    end

  end

  # GET /people/1
  # GET /people/1.rdf
  def show
    respond_to do |format|
      format.html { render :action => :show,  :layout => false }
      format.rdf  { render :rdf => @person } # http://blog.crowdvine.com/2007/11/04/implementing-foaf-in-rails/
      format.jpeg {
        if params[:flash] and params[:flash] == flash[:photo]
          filename = current_user.tempfile(flash[:photo])
          flash.keep(:photo)
        else
          # FIXME accelerate? without finding person first
          #filename = current_user.photo_path + params[:photo]
          filename = @person.photo_file
        end

        unless File.file?(filename)
          # Seems to be a linked photo, get it from the linked person
          # FIXME: todo
        end

        send_file(filename, :type => 'image/jpeg', :disposition => 'inline')
      }
    end
  end
  
  def show_many
    # make sure every person is accessible by the user
    # make sure only one linked person or the user itself is in the merge

    @people = []
    @people_ids = params[:people] || []
    @people_ids.each do |id|
      if person = Person.find(id) and person.user == current_user
        @people << person
      end
    end

    # If we checked only one person render show action
    case @people.size
    when 0
      render :nothing => true
    when 1
      @person = @people.first
      return self.show
    else
      render :layout => false
    end
  end

  # GET /people/new
  def new
    @person = Person.new

    if @people_ids = params[:people]
      # we want to merge somebody
      @people_ids.each do |id|
        # find it and make sure its mine
        if p = Person.find(id) and p.user == current_user
          @person.merge!(p)
        end
      end
    end


    add_new_to_empty_collection_details
    respond_to do |format|
      format.html { render :partial => 'form'}
    end
  end

  # GET /people/1/edit
  def edit
    add_new_to_empty_collection_details
    respond_to do |format|
      format.html { render :partial => 'form'}
    end
  end

  def edit_many_off
    # make sure every person is accessible by the user
    # make sure only one linked person or the user itself is in the merge

    @people = nil
    @people_ids = params[:people]
    unless @people_ids.nil? or params[:people].empty?
      @people = build_people_struct(params[:people])
    end

    # a new empty person, to set form.object, to create nested_attributes
    @person = Person.new
    if @people
      render :layout => false
    else
      render :partial => 'merge'
    end    
  end

  def merge
    # we come from a merge, so we want to overwrite one person and delete
    # the other ones.
    # make sure every person is accessible by the user
    # make sure only one linked person or the user itself is in the merge
    @people = []
    params[:people].each do |id|
      if person = Person.find(id) and person.user == current_user        
        if person == current_user.person
          raise 'try to merge unmergable' if @person
          @person = person
        elsif person.link
          # FIXME: make sure we dont merge two linked persons
          raise 'try to merge unmergable' if @person
          @person = person
        else
          @people << person
        end
      end
    end

    # just take the first person. The rest of the people array will be destroyed
    @person ||= @people.shift

    # delete all collection details, also the existing ones come in as new
    @person.collection_details.each do |d|
      @person.send(d).clear
    end
    
    if @person.update_attributes(params[:person])
      @people.each do |person|
        #person.event_destroy
        @person.merge_duplicates(person)
        person.destroy
      end
      flash[:notice] = 'Person successfully merged.'
      # also update people list
      @people = current_user.book.people.paginate(:page => 1) 
      #@person.event_create
      render :action => :show
    else
      render :action => :edit_many_error
    end
  end
  
  # POST /people
  def create
    respond_to do |format|

      format.jpeg do
        responds_to_parent do
          find_person
          if params[:photo]
            # if theres already a file, unlink it first
            if flash[:photo]
              current_user.tempfile(flash[:photo], :unlink)
            end
            # store the photo on disc and the key in flash
            flash[:photo] = current_user.tempfile(params[:photo])
            update_photo_and_hide_postcard
          else
            render :update do |page|
              page[:postcard_errors].replace_html 'upload something'
            end
          end
        end
      end

      format.js do
        @person = Person.new(params[:person])
        @person.user = current_user
        @person.photo = current_user.tempfile(flash[:photo], :data) if flash[:photo]

        if @person.save
          current_user.book.people << @person
          flash[:notice] = 'Person was successfully created.'
          # remove all people_ids
          destroy_people_ids

          # also update people list
          @people = current_user.book.people.paginate(:page => 1) 
          #@people = people_found.paginate(:page => params[:page])

          current_user.tempfile(flash[:photo], :unlink) if flash[:photo]
          #@person.event_create
          render :action => :show
        else
          flash.keep(:photo) # dont discard photo, we need it when we save
          render :action => :edit
        end
      end

    end
  end

  # PUT /people/1
  def update
    # in case no details are submitted, we have to init with an empty hash
    # see http://groups.google.com/group/attribute_fu/browse_thread/thread/2524cc74ed9920e4/b6fd6aed0d7641ef
    #@person.collection_details.each do |detail|
    #  # FIXME: can we get this _attributes faster? somewhere from the attribute_fu plugin ?
    # params[:person][(detail.to_s.singularize + '_attributes').to_sym] ||= {}
    #end
    old_display_name = @person.display_name
    # FIXME: this is a dirty hack.
    #   We should only set updated_at if really something changes
    @person.updated_at = Time.now
    respond_to do |format|
      format.js do
        params[:person][:photo] = current_user.tempfile(flash[:photo], :data) if flash[:photo]
        if @person.update_attributes(params[:person])
          flash[:notice] = 'Person was successfully updated.'
          #format.html { render :partial => 'person'}
          @person.event_update
          # FIXME: I have to reload, because collection details that have been
          #   removed are still displayed - this might be a bug in rails
          @person.reload
          if old_display_name != @person.display_name
            unless params[:dont_update_list] == 'true'
              # also reload the people list
              @people = current_user.book.people.paginate(:page => 1)
            end
          end
          current_user.tempfile(flash[:photo], :unlink) if flash[:photo]
          render :action => :show
        else
          # preserve the flash in case of an error
          flash.keep(:edit_user_person)
          flash.keep(:photo) # dont discard photo, we need it when we save
          render :action => :edit
        end
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.jpeg
  # see: https://urandom.de/trac/audress/wiki/UseCases/11
  def destroy
    # FIXME also use destroy_people_ids, to make use of destroy pre checks
    respond_to do |format|
      format.html do
        if @person.user.person != @person
          flash[:notice] = @person.display_name + " deleted."
          #@person.event_destroy
          #current_user.trash_person(@person)
          #@person.destroy
        else
          flash[:notice] = _('You cannot delte yourself')
        end
        redirect_to(people_url)
      end

      format.jpeg do
        current_user.tempfile(flash[:photo], :unlink) unless flash[:photo].blank?
        flash[:photo] = ''
        update_photo_and_hide_postcard
      end
    end
  end
  
  def destroy_many
    delete_count = destroy_people_ids
    flash[:notice] = delete_count.to_s + " contacts deleted."
    redirect_to(people_url)
  end

  private
  def destroy_people_ids
    delete_count = 0
    if @people_ids = params[:people]
      # we want to merge somebody
      @people_ids.each do |id|
        # find it and make sure its mine
        if (p = Person.find(id) and 
              p.user == current_user and
              p.user.person != p)      #dont destroy yourself

          # FIXME: handle links
          # FIXME: handle destroy errors

          p.destroy
          delete_count += 1
          #p.event_destroy

        end
      end
    end
    delete_count
  end

  def update_photo_and_hide_postcard
    #has_photo = (@person.photo or flash[:photo])
    @person ||= Person.new
    render :update do |page|
      # url_for(:action => 'photo', :id => @person.id, :photo => @person.photo)
      # id => Time is needed to avoid browser caching

      photo_src =
        flash[:photo].blank? ? image_path('head.png') :
        url_for(:action => 'show', :id => @person.id || 0,
          :flash => flash[:photo], :format => 'jpeg')

      page[dom_id(@person, :photo)]['src'] = photo_src
      page[:postcard_photo]['src'] = photo_src
        
      #person_path(:id => -1, :flash => flash[:photo], :format => 'jpeg')
      page[:postcard].hide
      flash[:photo].blank? ?
        page[:postcard_remove_photo].hide :
        page[:postcard_remove_photo].show
      page[:postcard_errors].replace_html ''
    end
  end

  def find_person
    @person = params[:id].to_i > 0 ? Person.find(params[:id]) : Person.new
    # make sure its accessable
    if !@person.new_record? and @person.user != current_user
      # FIXME: do we store people elsewhere than default book?
      #unless current_user.book.exists?(@person)
      # flash warn here, dont raise exception, user needs to know whats going on
      flash[:warning] = 'You dont have permission to access this Person via URL'
      redirect_to(people_url)
      #end
    end
  end

  def add_new_to_empty_collection_details
    @person.collection_details.each do |d|
      if @person.send(d).empty?
        @person.send(d).build
      end
    end
  end

end
