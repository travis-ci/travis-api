require 'travis/legacy_api'

module Services
  module Repository
    module Caches
      class Delete
        include Travis::LegacyAPI
        attr_reader :repository

        def initialize(repository)
          @repository = repository
        end

        def access_token
          admin = repository.find_admin
          Travis::AccessToken.create(user: admin, app_id: 2).token if admin
        end

        def call(branch = nil)
          url = "/repos/#{repository.id}/caches"
          if branch.nil?
            body = {}
            # Will delete all caches
          else
            body = "{\"branch\": \"#{branch}\"}"
            # Will delete branch cache
          end
          delete(url, access_token, body)
        end
      end
    end
  end
end
