module Travis
  module Api
    module V1
      module Archive
        class Build
          autoload :Job, 'travis/api/v1/archive/build/job'

          include Formats

          attr_reader :build, :commit, :repository

          def initialize(build, options = {})
            @build = build
            @commit = build.commit
            @repository = build.repository
          end

          def data
            {
              'id' => build.id,
              'number' => build.number,
              'config' => build.obfuscated_config.stringify_keys,
              'result' => 0,
              'started_at' => format_date(build.started_at),
              'finished_at' => format_date(build.finished_at),
              'duration' => build.duration,
              'commit' => commit.commit,
              'branch' => commit.branch,
              'message' => commit.message,
              'committed_at' => format_date(commit.committed_at),
              'author_name' => commit.author_name,
              'author_email' => commit.author_email,
              'committer_name' => commit.committer_name,
              'committer_email' => commit.committer_email,
              'matrix' => build.matrix.map { |job| Job.new(job).data },
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
