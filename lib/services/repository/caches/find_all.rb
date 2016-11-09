require 'travis/legacy_api'

module Services
  module Repository
    module Caches
      class FindAll
        include Travis::LegacyAPI
        def initialize(repository_id)
          @repository_id = repository_id
        end

        def call
          url = "/repos/#{@repository_id}/caches"
          extract_caches(get(url))
        end

        private

        def extract_caches(response)
          response = JSON.parse(response.body, symbolize_names: true)
          response[:caches]
        rescue
          []
        end
      end
    end
  end
end
