module Travis
  module Api
    module Serialize
      module V0
        module Notification
          class Repository
            attr_reader :repository

            def initialize(repository, options = {})
              @repository = repository
            end

            def data
              {
                'repository' => repository_data
              }
            end

            def repository_data
              {
                'id' => repository.id,
                'slug' => repository.slug
              }
            end
          end
        end
      end
    end
  end
end
