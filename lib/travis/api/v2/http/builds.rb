module Travis
  module Api
    module V2
      module Http
        class Builds
          include Formats

          attr_reader :builds, :commits, :options

          def initialize(builds, options = {})
            @builds = builds
            @commits = builds.map(&:commit)
            @options = options
          end

          def data
            {
              'builds' => builds.map { |build| build_data(build) },
              'commits' => commits.map { |commit| commit_data(commit) }
            }
          end

          private

            def build_data(build)
              {
                'id' => build.id,
                'repository_id' => build.repository_id,
                'commit_id' => build.commit_id,
                'number' => build.number,
                'pull_request' => build.pull_request?,
                'pull_request_title' => build.pull_request_title,
                'pull_request_number' => build.pull_request_number,
                'config' => build.obfuscated_config.stringify_keys,
                'state' => build.state.to_s,
                'started_at' => format_date(build.started_at),
                'finished_at' => format_date(build.finished_at),
                'duration' => build.duration,
                'job_ids' => matrix_ids(build)
              }
            end

            def matrix_ids(build)
              build.cached_matrix_ids || build.matrix_ids
            end

            def commit_data(commit)
              {
                'id' => commit.id,
                'sha' => commit.commit,
                'branch' => commit.branch,
                'message' => commit.message,
                'committed_at' => format_date(commit.committed_at),
                'author_name' => commit.author_name,
                'author_email' => commit.author_email,
                'committer_name' => commit.committer_name,
                'committer_email' => commit.committer_email,
                'compare_url' => commit.compare_url,
                'pull_request_number' => commit.pull_request_number
              }
            end
        end
      end
    end
  end
end
