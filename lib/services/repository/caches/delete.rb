require 'travis/legacy_api'

module Services
  module Repository
    module Caches
      class Delete
        def initialize(repository_id)
          @repository_id = repository_id
        end

        def call(branch)
          url = "/repos/#{@repository_id}/caches"
          if branch.nil?
            body = nil
            # Will delete all caches
          else
            body = "{'branch':'#{branch}'}"
            # Will delete branch cache
          end
          delete(url, body)
        end
      end
    end
  end
end