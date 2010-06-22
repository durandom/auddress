namespace(:db) do
  require File.join(File.dirname(__FILE__), 'helpers')

  FIXTURE_DIRECTORY = path('test', 'fixtures', RAILS_ENV)

  namespace(:fixtures) do
    desc("Create YAML test fixtures from the data in the current environment's database.")
    task(:generate => :environment) do
      ActiveRecord::Base.establish_connection

      # Create the fixtures directory if it doesn't exist.
      Dir.mkdir(FIXTURE_DIRECTORY) unless File.exist?(FIXTURE_DIRECTORY)
      # Delete any existing fixture files.
      system("rm #{File.join(FIXTURE_DIRECTORY, '*.yml')}")

      # Dump each table in the database to a separate YAML fixtures file.
      tables.each do |table_name|
        puts(table_name)
        File.open(File.join(FIXTURE_DIRECTORY, "#{table_name}.yml"), 'w') do |file|
          i = "00000"
          # Convert each row retrieved from the query into YAML.
          file.write ActiveRecord::Base.connection.select_all("SELECT * FROM #{table_name}").inject({}) { |hash, row|
            hash["#{table_name}_#{i.succ!}"] = row
            hash
          }.to_yaml
        end
      end
    end
  end

  desc("Removes all the data from the current environment's database, but does not drop the database itself.")
  task(:empty => :environment) do
    return unless destructive_tasks_allowed?
    tables.each do |table_name|
      ActiveRecord::Base.connection.delete("TRUNCATE #{table_name}")
    end
  end

  desc("Drops the current environment's database and recreates it.")
  task(:recreate => :environment) do
    return unless destructive_tasks_allowed?
    database = ActiveRecord::Base.configurations[RAILS_ENV]['database']
    system("mysql -e 'DROP DATABASE #{database}; CREATE DATABASE #{database};'")
  end

  desc("Drops and recreates the current environment's database and reruns all migrations.")
  task(:remigrate => :environment) do
    puts('Recreating database...')
    Rake::Task['db:recreate'].invoke
    Rake::Task['db:migrate'].invoke
  end

  namespace(:migrate) do
    desc('Migrate all databases through scripts in db/migrate. Target specific version with VERSION=x.')
    task(:all => :environment) do
      ActiveRecord::Base.configurations.each do |environment, configuration|
        puts("Migrating #{environment}...")
        system("rake RAILS_ENV=#{environment} db:migrate")
      end
    end
  end

  namespace(:remigrate) do
    desc("Drops and recreates each environment's database and reruns all migrations on each of them.")
    task(:all => :environment) do
      ActiveRecord::Base.configurations.each do |environment, configuration|
        puts("Remigrating #{environment}...")
        system("rake RAILS_ENV=#{environment} db:remigrate")
      end
    end
  end

  namespace(:migrations) do
    desc("Tests any uncommitted migrations by remigrating the current environment's database, migrating back to the last committed revision, and then migrating forward again. Specify the number of migrations to test with NUMBER=x.")
    task(:test => :environment) do
      Rake::Task['db:remigrate'].invoke

      ActiveRecord::Base.establish_connection
      latest_version = ActiveRecord::Base.connection.select_value("SELECT version FROM schema_info LIMIT 1").to_i

      go_back = ENV['NUMBER'] || uncommitted_migrations.size

      system("rake db:migrate VERSION=#{latest_version - go_back.to_i}")
      system("rake db:migrate")
    end

    desc("Renames the files for all uncommitted migrations so that they follow, numerically, any migrations that have already been added to the codebase.")
    task(:merge => :environment) do
      all = `ls -1 #{migration_directory}`.split("\n")
      uncommitted = uncommitted_migrations.collect { |s| File.basename(s) }
      max = (all - uncommitted).collect { |s| s[0..2].to_i }.max

      uncommitted.sort.each do |filename|
        max += 1
        full_filename = migration_directory(filename)
	new_filename = migration_directory("#{'%03d' % max}_#{filename[4..-1]}")
        versioned = false

	# If the file has already been added to version control, revert it first.
	if `svn status #{full_filename} | awk '{print $1}'` == "A\n"
	   versioned = true
	   system("svn revert --quiet #{full_filename}")
        end

	File.rename(full_filename, new_filename)

        # Add it to version control again.
	system("svn add --quiet #{new_filename}") if versioned
      end
    end
  end
end
