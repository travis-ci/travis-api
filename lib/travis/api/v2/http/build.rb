module Travis
  module Api
    module V2
      module Http
        class Build
          include Formats

          attr_reader :build, :options

          def initialize(build, options = {})
            options[:include_jobs] = true unless options.key?(:include_jobs)

            @build = build
            @options = options
          end

          def data
            {
              'build'  => build_data(build),
              'commit' => commit_data(build.commit),
              'jobs'   => options[:include_jobs] ? build.matrix.map { |job| job_data(job) } : [],
              'annotations' => options[:include_jobs] ? Annotations.new(annotations(build), @options).data["annotations"] : [],
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
                'job_ids' => build.matrix_ids
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

            def job_data(job)
              {
                'id' => job.id,
                'repository_id' => job.repository_id,
                'build_id' => job.source_id,
                'commit_id' => job.commit_id,
                'log_id' => job.log_id,
                'state' => job.state.to_s,
                'number' => job.number,
                'config' => job.obfuscated_config.stringify_keys,
                'started_at' => format_date(job.started_at),
                'finished_at' => format_date(job.finished_at),
                'queue' => job.queue,
                'allow_failure' => job.allow_failure,
                'tags' => job.tags,
                'annotation_ids' => job.annotation_ids,
              }
            end

            def annotations(build)
              build.matrix.map(&:annotations).flatten
            end
        end
      end
    end
  end
end
