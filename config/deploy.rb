set :application, "auddress"

set :shared_children,   %w(system log pids data)

#set :runner, "auddress"
set :use_sudo, false
set :user, 'staging'
set :scm_username, 'hild'
#set :scm_password, ''
set :scm_auth_cache, true
set :rails_env, 'staging'
set :runner, 'staging'

set :domain, "staging.auddress.com"


# explanation: http://www.mail-archive.com/capistrano@googlegroups.com/msg02817.html
default_run_options[:pty] = true

#### repositories and paths
#
set :deploy_to, "/srv/www-data/staging/"
set :repository,  "https://developers.auddress.com/svn/#{application}/trunk/"
#set :repository,  "file:///srv/svn/#{application}/trunk/"
set :disable_template, 'lib/maintenance.html.erb'

role :app, domain
role :web, domain
role :db,  domain, :primary => true

before "deploy:update_code", "deploy:web:disable"
after "deploy:restart", "deploy:web:enable"
after "deploy:update_code", 'deploy:link_data'

#desc "Restart the web server"
#task :restart, :roles => [:app, :web, :db] do
#  sudo "/etc/init.d/apache2 reload"
#end

# http://ariejan.net/2006/12/13/show-the-current-svn-revision-in-your-rails-app/
desc "Write current revision to app/layouts/_revision.rhtml"
task :publish_revision do
  run "svn info #{release_path} | grep ^Revision > #{release_path}/app/views/layouts/_revision.html.erb"
end

desc "Run this after update_code"
task :after_update_code do
  publish_revision
end

desc "Generate a maintenance.html to disable requests to the application."
deploy.web.task :disable, :roles => :web do
  remote_path = "#{shared_path}/system/maintenance.html"
  on_rollback { run "rm #{remote_path}" }
  template = File.read(disable_template)
  deadline, reason = ENV["UNTIL"], ENV["REASON"]
  maintenance = ERB.new(template).result(binding)
  put maintenance, "#{remote_path}", :mode => 0644
end

namespace :deploy do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  desc "Link DataDir"
  task :link_data, :roles => :app do
    run <<-CMD
      ( test -d #{shared_path}/data || ( mkdir #{shared_path}/data &&  chmod 775 #{shared_path}/data ) ) &&
      test ! -L #{latest_release}/data &&
      cp -af #{latest_release}/data #{shared_path} &&
      rm -rf #{latest_release}/data &&
      ln -s #{shared_path}/data #{latest_release}/data
    CMD
  end
end
