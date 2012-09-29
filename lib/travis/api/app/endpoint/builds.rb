require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Builds < Endpoint
      get '/' do
        body all(params).run
      end

      get '/:id' do
        body one(params).run
      end
    end
  end
end
