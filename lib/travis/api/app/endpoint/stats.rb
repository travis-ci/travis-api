require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Stats < Endpoint
      get '/repos' do
        { :stats => service(:daily_repos) }
      end

      get '/tests' do
        { :stats => service(:daily_tests) }
      end
    end
  end
end
