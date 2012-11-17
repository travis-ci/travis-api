require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Stats < Endpoint
      get '/repos' do
        { :stats => service(:find_daily_repos_stats) }
      end

      get '/tests' do
        { :stats => service(:find_daily_tests_stats) }
      end
    end
  end
end
