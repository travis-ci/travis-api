require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Branches < Endpoint
      get '/' do
        respond_with service(:find_branches, params), type: :branches
      end

      # get '/:owner_name/:name/branches' do       # v1
      # get '/repos/:owner_name/:name/branches' do # v2
      #   respond_with service(:branches, :find_all, params), type: :branches
      # end
    end
  end
end
