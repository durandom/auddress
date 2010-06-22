PROTECTED_ENVIRONMENTS = %w(production)
SKIP_TABLES = %w(schema_info)

def tables
  ActiveRecord::Base.connection.tables - SKIP_TABLES
end

def destructive_tasks_allowed?
  allow = !PROTECTED_ENVIRONMENTS.include?(RAILS_ENV)
  puts('This task is not allowed in the following environments: ' + PROTECTED_ENVIRONMENTS.join) unless allow
  allow
end

def path(*arguments)
  File.join(RAILS_ROOT, *arguments)
end

def quoted_path(*arguments)
  "'#{path(*arguments)}'"
end

def migration_directory(*arguments)
  path('db', 'migrate', *arguments)
end

def uncommitted_migrations
  `svn status #{migration_directory} | awk '{if ($1 == "?" || $1 == "A") print $2}'`.split("\n")
end
