module Travis
  module Api
    module V2
      module Http
        class Branches
          include Formats

          attr_reader :builds, :commits, :options

          def initialize(builds, options = {})
            builds = builds.last_finished_builds_by_branches if builds.is_a?(Repository) # TODO remove, bc
            @builds = builds
            @commits = builds.map(&:commit)
            @options = options
          end

          def data
            {
              'branches' => builds.map { |build| build_data(build) },
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
                'config' => build.obfuscated_config.stringify_keys,
                'state' => build.state.to_s,
                'started_at' => format_date(build.started_at),
                'finished_at' => format_date(build.finished_at),
                'duration' => build.duration,
                'job_ids' => build.matrix.map { |job| job.id },
                'pull_request' => build.pull_request?
              }
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
              }
            end
        end
      end
    end
  end
end
