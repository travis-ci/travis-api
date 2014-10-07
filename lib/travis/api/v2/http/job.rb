module Travis
  module Api
    module V2
      module Http
        class Job
          include Formats

          attr_reader :job, :options

          def initialize(job, options = {})
            @job = job
            @options = options
          end

          def data
            {
              'job' => job_data(job),
              'commit' => commit_data(job.commit),
              'annotations' => Annotations.new(job.annotations, @options).data["annotations"],
            }
          end

          private

            def job_data(job)
              {
                'id' => job.id,
                'repository_id' => job.repository_id,
                'repository_slug' => job.repository.slug,
                'build_id' => job.source_id,
                'commit_id' => job.commit_id,
                'log_id' => job.log_id,
                'number' => job.number,
                'config' => job.obfuscated_config.stringify_keys,
                'state' => job.state.to_s,
                'started_at' => format_date(job.started_at),
                'finished_at' => format_date(job.finished_at),
                'queue' => job.queue,
                'allow_failure' => job.allow_failure,
                'tags' => job.tags,
                'annotation_ids' => job.annotation_ids,
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
