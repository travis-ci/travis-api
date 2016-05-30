module Travis
  module Api
    module V1
      module Http
        class Builds
          include Formats, Helpers::Legacy

          attr_reader :builds

          def initialize(builds, options = {})
            @builds = builds
          end

          def data
            builds.map { |build| build_data(build) }
          end

          def build_data(build)
            {
              'id' => build.id,
              'repository_id' => build.repository_id,
              'number' => build.number,
              'state' => legacy_build_state(build),
              'result' => legacy_build_result(build),
              'started_at' => format_date(build.started_at),
              'finished_at' => format_date(build.finished_at),
              'duration' => build.duration,
              'commit' => build.commit.commit,
              'branch' => build.commit.branch,
              'message' => build.commit.message,
              'event_type' => build.event_type,
            }
          end
        end
      end
    end
  end
end
