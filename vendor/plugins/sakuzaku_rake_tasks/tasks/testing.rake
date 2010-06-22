#  namespace(:test) do
#    desc('Run the functional tests and validate their XHTML and CSS output.')
#    task(:markup => :environment) do
#      require 'vendor/plugins/assert_valid_asset/lib/assert_valid_asset.rb'
#      # Assert that each test method of each TestCase outputs valid markup.
# class Test::Unit::TestCase
#  def setup_with_markup_assert
#    method_names = methods
#    tests = method_names.delete_if { |method_name| method_name !~ /^test./ }.collect(&:to_sym)
#    puts tests.inspect
#    self.class.assert_valid_markup :index
#    #assert_valid_css_files File.glob(File.join(RAILS_ROOT, 'public', 'stylesheets', '*.css'))
#  end
#
#  alias_method :setup, :setup_with_markup_assert
#
#  def self.method_added(method_symbol)
#    if method_symbol == :setup && !method_defined?(:setup_without_markup_assert)
#      alias_method :setup_without_markup_assert, :setup
#      define_method(:setup) do
#        setup_with_markup_assert
#        setup_without_markup_assert
#      end
#    end
#  end
# end
#      # Run the functional tests.
#      Rake::Task['test:functionals'].invoke
#    end
#  end

rule('') do |t|
  Rake::Task['db:test:prepare'].invoke

  t.name.match(/(.+?)(-([ufi]))?(:(.+))?$/)
  possible_file = $1
  type = $3
  test_name = $5

  file_pattern = case type
    when 'u': ['unit', "#{possible_file}_test.rb"]
    when 'f': ['functional', "#{possible_file}_controller_test.rb"]
    when 'i': ['integration', "#{possible_file}_test.rb"]
    else     ['**', "#{possible_file}_{test,controller_test}.rb"]
  end

  files = Dir.glob(File.join(RAILS_ROOT, 'test', *file_pattern))
  files.each do |file|
    test_method = "test_#{test_name}"
    test_exists = `grep --count 'def #{test_method}' #{file}`.to_i.nonzero?

    command  = "ruby '#{file}'"
    command += " -n /^#{test_method}/" if test_name

    # Only run the test set if the specified test method exists.
    if test_name.nil? || test_exists
      system(command)
    end
  end
end
