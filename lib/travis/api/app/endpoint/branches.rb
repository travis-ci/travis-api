require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Branches < Endpoint
      # TODO: Add documentation.
      get('/') do
        body repository, :type => "Branches"
      end

      private

        def repository
          pass if params.empty?
          Repository.find_by(params) || not_found
        end
    end
  end
end
