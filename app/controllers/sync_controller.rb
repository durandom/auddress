class SyncController < ApplicationController
  before_filter :login_required
  before_filter :find_sync_source, 
    :only => [:delete, :outlook, :funambol, :phone, :google, :vcard, :vcf, :sync]

  def find_sync_source
    if params[:id]
      @sync_source = SyncSource.find(params[:id])
      unless @sync_source.user == current_user
        logger.warn("no access to syncsource #{@sync_source.id} by user #{current_user.id}")
        redirect_to(root_url)
      end
    end
  end

  # only shows a list of possible syncsources
  def add    
  end
  
  def delete
    @sync_source.destroy
    flash[:notice] = "deleted..."
    redirect_to :action => 'info'
  end

  def info
    @sync_sources = SyncSource.find_all_by_user_id(current_user, :order => 'id ASC')
    # maybe remove the first one, this is the backup syncsource
    #@sync_sources.shift
    
    #@google   = SyncSourceGoogle.find_all_by_user_id(current_user)
    #@sync_source = SyncSourceFunambol.find_all_by_user_id(current_user.id)
    #@vcard    = SyncSourceFunambol.find_all_by_user_id(current_user.id)
  end

  def sync
    @log = []
    if @sync_source
      engine = SyncEngine.new(:sync_source => @sync_source)
      engine.sync
      @log.concat(engine.log)
    else
      SyncSource.find_all_by_user_id(current_user).each do |ss|
        engine = SyncEngine.new(:sync_source => ss)
        engine.sync
        @log.concat(engine.log)
      end
    end
  end

  # this is the callback by google to approve us
  def google   
    if params[:token]
      # make sure the syncsource does not exist with this token for this user
      # e.g. the user hits reload. If so, we just show the syncsource
      #      SyncSourceGoogle.find_all_by_user_id(current_user).each do |s|
      #        if s.token == token
      #          @sync_source = s
      #          break
      #        end
      #      end
      # no sync source for this token? create a new one
      @sync_source = SyncSourceGoogle.new
      @sync_source.user = current_user

      # convert token to a session token, which does not expire
      token = Contacts::Google.session_token(params[:token])
      unless token.blank?
        @sync_source.configuration = token
        @sync_source.save
      end
    end
  end

  def outlook
    unless @sync_source
      funambol
      @sync_source.client = 'outlook'
      @sync_source.save
    end
  end

  def phone
    unless @sync_source
      funambol
      @sync_source.client = 'phone'
      @sync_source.save
    end
  end

  def funambol
    unless @sync_source
      @sync_source = SyncSourceFunambol.new
      @sync_source.user = current_user
      @sync_source.save
      @sync_source.client = 'generic'
      @sync_source.save
    end
  end

  def vcard
  end

  def vcf
    # FIXME filter X-AUDRESS-UID from vcard file?
    send_data(
      File.open(@sync_source.filename).read,
      :type => 'application/vcard',
      :filename => "#{current_user.login}.vcf", # some unique filename
      :disposition => 'inline'
    )
  end

  def sync_google
    ss = SyncSourceGoogle.find_by_user_id(current_user)
    engine = SyncEngine.new(:sync_source => ss)
    engine.sync
    @log = engine.log
  end

  def next_conflict_item
    @conflict = nil
    SyncSource.find_all_by_user_id(current_user).each do |ss|
      break if @conflict = ss.sync_items.conflict.first
    end
    @conflict
  end

  def conflict
    next_conflict_item
    unless @conflict
      flash[:notice] = 'Nothing more to resolve'
      redirect_to root_url
    end
  end

  def resolve
    # FIXME: ensure access
    @conflict = SyncItem.find(params[:id])

    respond_to do |format|
      if @conflict.resolve(params[:resolve])
        flash[:notice] = 'Will be reolved on next sync'
        if next_conflict_item
          format.html { render :action => :conflict }
        else
          format.html {redirect_to root_url}
        end
      else
        format.html { render :action => :conflict }
      end
    end
  end
end
