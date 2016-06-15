module Travis
  module Api
    module V1
      module Http
        class Repository
          include Formats, Helpers::Legacy

          attr_reader :repository, :options

          def initialize(repository, options = {})
            @repository = repository
          end

          def data
            {
              'id' => repository.id,
              'slug' => repository.slug,
              'description' => repository.description,
              'public_key' => repository.key.public_key,
              'last_build_id' => repository.last_build_id,
              'last_build_number' => repository.last_build_number,
              'last_build_status' => legacy_repository_last_build_result(repository),
              'last_build_result' => legacy_repository_last_build_result(repository),
              'last_build_duration' => repository.last_build_duration,
              'last_build_language' => nil,
              'last_build_started_at' => format_date(repository.last_build_started_at),
              'last_build_finished_at' => format_date(repository.last_build_finished_at),
            }
          end
        end
      end
    end
  end
end
