require 'travis/legacy_api'

module Services
  module Repository
    module Caches
      class FindAll
        include Travis::LegacyAPI
        attr_reader :repository

        def initialize(repository)
          @repository = repository
        end

        def access_token
          admin = repository.find_admin
          Travis::AccessToken.create(user: admin, app_id: 2).token if admin
        end

        def call
          url = "/repos/#{repository.id}/caches"
          extract_caches(get(url, access_token))
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
