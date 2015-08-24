unless ENV['SKIP_COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    coverage_dir '.coverage'
    add_filter "/spec/"
    add_group "v3", "lib/travis/api/v3"
  end
end
