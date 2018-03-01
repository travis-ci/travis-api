require 'travis/api'

module Services
  module Repository
    module Caches
      class Delete
        include Travis::API
        attr_reader :repository

        def initialize(repository)
          @repository = repository
        end

        def access_token
          admin = repository.find_admin
          Travis::AccessToken.create(user: admin, app_id: 2).token if admin
        end

        def call(branch = nil)
          if branch.nil?
            url = "/repo/#{repository.id}/caches"
            # Will delete all caches
          else
            url = "/repo/#{repository.id}/caches?branch=#{branch}"
            # Will delete branch cache
          end
          delete(url, access_token)
        end
      end
    end
  end
end
