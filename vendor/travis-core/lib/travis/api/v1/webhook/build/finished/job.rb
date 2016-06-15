module Travis
  module Api
    module V1
      module Webhook
        class Build
          class Finished < Build
            class Job
              include Formats

              attr_reader :job, :commit, :options

              def initialize(job, options = {})
                @job = job
                @commit = job.commit
                @options = options
              end

              def data
                data = {
                  'id' => job.id,
                  'repository_id' => job.repository_id,
                  'parent_id' => job.source_id,
                  'number' => job.number,
                  'state' => job.finished? ? 'finished' : job.state.to_s,
                  'config' => job.obfuscated_config,
                  'status' => job.result,
                  'result' => job.result,
                  'commit' => commit.commit,
                  'branch' => commit.branch,
                  'message' => commit.message,
                  'compare_url' => commit.compare_url,
                  'committed_at' => format_date(commit.committed_at),
                  'author_name' => commit.author_name,
                  'author_email' => commit.author_email,
                  'committer_name' => commit.committer_name,
                  'committer_email' => commit.committer_email,
                  'allow_failure' => job.allow_failure
                }
                data['log'] = job.log_content || '' if options[:include_logs]
                data['started_at'] = format_date(job.started_at) if job.started?
                data['finished_at'] = format_date(job.finished_at) if job.finished?
                data
              end
            end
          end
        end
      end
    end
  end
end
