require 'travis/api/serialize/formats'

module Travis
  module Api
    module Serialize
      module V2
        module Http
          class Repositories
            include Formats

            attr_reader :repositories, :options

            def initialize(repositories, options = {})
              @repositories = repositories
              @options = options
            end

            def data
              {
                'repos' => repositories.map { |repository| repository_data(repository) }
              }
            end

            private

              def repository_data(repository)
                {
                  'id' => repository.id,
                  'slug' => repository.slug,
                  'description' => repository.description,
                  'last_build_id' => repository.last_build_id,
                  'last_build_number' => repository.last_build_number,
                  'last_build_state' => repository.last_build_state.to_s,
                  'last_build_duration' => repository.last_build_duration,
                  'last_build_language' => nil,
                  'last_build_started_at' => format_date(repository.last_build_started_at),
                  'last_build_finished_at' => format_date(repository.last_build_finished_at),
                  'active' => repository.active,
                  'github_language' => repository.github_language
                }
              end
          end
        end
      end
    end
  end
end
