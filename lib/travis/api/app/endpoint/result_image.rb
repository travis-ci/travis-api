require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class ResultImage < Endpoint
      set(:prefix) { '/' }

      get '/:owner_name/:name.png' do
        result_image service(:repositories, :one, params).run(:raise => false)
      end
    end
  end
end
