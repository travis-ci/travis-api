module Travis
  module Api
    module V0
      module Event
        class Build
          include Formats

          attr_reader :build, :repository, :request, :commit, :options

          def initialize(build, options = {})
            @build = build
            @repository = build.repository
            @request = build.request
            @commit = build.commit
            # @options = options
          end

          def data(extra = {})
            {
              'repository' => repository_data,
              'request' => request_data,
              'commit' => commit_data,
              'build' => build_data,
              'jobs' => build.matrix.map { |job| job_data(job) }
            }
          end

          private

            def build_data
              {
                'id' => build.id,
                'repository_id' => build.repository_id,
                'commit_id' => build.commit_id,
                'number' => build.number,
                'pull_request' => build.pull_request?,
                'pull_request_number' => build.pull_request_number,
                'config' => build.config.try(:except, :source_key),
                'state' => build.state.to_s,
                'previous_state' => build.previous_state.to_s,
                'started_at' => format_date(build.started_at),
                'finished_at' => format_date(build.finished_at),
                'duration' => build.duration,
                'job_ids' => build.matrix_ids
              }
            end

            def repository_data
              {
                'id' => repository.id,
                'key' => repository.key.try(:public_key),
                'slug' => repository.slug,
                'name' => repository.name,
                'owner_email' => repository.owner_email,
                'owner_avatar_url' => repository.owner.try(:avatar_url)
              }
            end

            def request_data
              {
                'token' => request.token,
                'head_commit' => (request.head_commit || '')
              }
            end

            def commit_data
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

            def job_data(job)
              {
                'id' => job.id,
                'number' => job.number,
                'state' => job.state.to_s,
                'tags' => job.tags
             }
            end
        end
      end
    end
  end
end


