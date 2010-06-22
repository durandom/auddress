namespace(:app) do
  require File.join(File.dirname(__FILE__), 'helpers')

  desc('Initializes a newly-created Rails application.')
  task(:initialize) do
    database_stub = path('config', 'database.yml.stub')

    # Change the default database configuration file to a stub.
    system("svn mv #{quoted_path('config', 'database.yml')} '#{database_stub}'")

    # Ignore the non-stub database configuration file that will be created in every working copy.
    system("svn propset svn:ignore database.yml #{quoted_path('config')}")

    # Ignore the database schema dump that Rails creates when you run certain rake tasks.
    system("svn propset svn:ignore schema.rb #{quoted_path('db')}")

    # Ignore all log files.
    system("svn propset svn:ignore '*' #{quoted_path('log')}")

    # Ignore documentation.
    system("svn propset svn:ignore \"app\napi\" #{quoted_path('doc')}")

    # Ignore all temporary files in all temporary directories.
    system("find #{quoted_path('tmp')} -mindepth 1 -maxdepth 2 -type d \! -path '*.svn*' -print0 | xargs -0 svn propset svn:ignore '*'")

    # Mark all scripts as executable.
    system("find #{quoted_path('script')} -type f \! -path '*.svn*' -print0 | xargs -0 svn propset svn:executable ''")

    # Remove all log files from version control.
    system("svn rm #{quoted_path('log', '*')}")

    # Create each MySQL database.
    require 'yaml'
    YAML.load_file(database_stub).each do |environment, settings|
      system("mysql -e 'CREATE DATABASE #{settings['database']};'")
    end
  end
end
