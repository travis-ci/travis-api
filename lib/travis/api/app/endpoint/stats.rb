require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Stats < Endpoint
      # TODO: Add documentation.
      get('/repos') do
        { :stats => service(:stats).daily_repository_counts }
      end

      # TODO: Add documentation.
      get('/tests') do
        { :stats => service(:stats).daily_tests_counts }
      end
    end
  end
end
