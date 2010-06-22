require 'grit' #mojombo-grit
include Grit

class Backup
  attr_accessor :sync_source

  def initialize(sync_source)
    self.sync_source = sync_source

    dir=File.dirname(sync_source.filename)
    unless File.directory?( dir +'/.git' )
      @repo = Repo.init_bare(dir+'/.git')
    else
      @repo = Repo.new(dir)
    end
  end

  def commit(msg)
    @repo.add(sync_source.filename)
    #@repo.commit_all(msg)
    if e=sync_source.user.person.emails.first
      author = e.email_address_with_name
    else
      # FIXME: use better default
      author = "Audress Backup System <hild@b4mad.net>"
    end
    @repo.git.commit({}, '-a', "--author=\"#{author}\"", '-m', msg)
  end
  
  def history
    @repo.commits('master', false)
  end

  def restore(cid)
    if commit = @repo.commit(cid)
      obj = commit.tree
      # recurse into the data tree until we encounter the first blob
      while (obj = obj.contents.first)
        if obj.class == Grit::Blob
          return obj.data
        end
      end
    end
  end
  
  def repo
    @repo
  end


end
