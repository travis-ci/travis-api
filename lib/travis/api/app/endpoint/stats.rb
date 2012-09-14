require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Stats < Endpoint
      # TODO: Add documentation.
      get('/repos') do
        { :stats => services(:stats).daily_repository_counts }
      end

      # TODO: Add documentation.
      get('/tests') do
        { :stats => services(:stats).daily_tests_counts }
      end
    end
  end
end
