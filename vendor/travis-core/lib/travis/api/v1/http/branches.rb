require 'travis/api/v1/helpers/legacy'

module Travis
  module Api
    module V1
      module Http
        class Branches
          include Formats, Helpers::Legacy

          attr_reader :builds, :options

          def initialize(builds, options = {})
            builds = builds.last_finished_builds_by_branches if builds.is_a?(Repository) # TODO remove, bc
            @builds = builds
          end

          def cache_key
            "branches-#{builds.map(&:id).join('-')}"
          end

          def updated_at
            builds.compact.map(&:finished_at).compact.sort.first
          end

          def data
            builds.compact.map do |build|
              {
                'repository_id' => build.repository_id,
                'build_id' => build.id,
                'commit' => build.commit.commit,
                'branch' => build.commit.branch,
                'message' => build.commit.message,
                'result' => legacy_build_result(build),
                'finished_at' => format_date(build.finished_at),
                'started_at' => format_date(build.started_at)
              }
            end
          end
        end
      end
    end
  end
end
