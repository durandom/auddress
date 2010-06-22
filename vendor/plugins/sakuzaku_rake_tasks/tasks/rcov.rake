begin
  require 'rcov/rcovtask'

  namespace(:test) do
    COVERAGE_DIRECTORY = File.join(RAILS_ROOT, 'test', 'coverage')

    namespace(:coverage) do
      desc('Delete aggregate coverage data.')
      task(:clean) do
        rm_f(File.join(COVERAGE_DIRECTORY, 'coverage.data'))
      end
    end
    
    desc('Produce aggregated code coverage reports for unit, functional and integration tests with RCov.')
    task(:coverage => 'sakuzaku:test:coverage:clean')
    ['unit', 'functional', 'integration'].each do |target|
      namespace(:coverage) do
        Rcov::RcovTask.new(target) do |t|
          t.libs << 'test'
          t.test_files = FileList[File.join(RAILS_ROOT, 'test', target, '**', '*_test.rb')]
          t.output_dir = File.join(COVERAGE_DIRECTORY, 'output')
          t.verbose = true
          # TODO: Create a YAML file in config to control exclude options for this task.
	  # TODO: Get these exclude definitions working again.
          #t.rcov_opts << "--rails --exclude lib/debug\\\\.rb,app/controllers/mail_test_controller\\\\.rb --sort coverage --aggregate '#{File.join(COVERAGE_DIRECTORY, 'coverage.data')}'"
          t.rcov_opts << "--rails --sort coverage --aggregate '#{File.join(COVERAGE_DIRECTORY, 'coverage.data')}'"
        end
      end
      task(:coverage => "sakuzaku:test:coverage:#{target}")
    end
  end
rescue LoadError
  # RCov must be installed!
end
