require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Branches < Endpoint
      get '/' do
        respond_with all(params), type: :branches
      end

      # get '/:owner_name/:name/branches' do       # v1
      # get '/repos/:owner_name/:name/branches' do # v2
      #   respond_with all(params), type: :branches
      # end
    end
  end
end
