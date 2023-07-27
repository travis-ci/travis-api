require 'travis/api/serialize/formats'

module Travis
  module Api
    module Serialize
      module V2
        module Http
          class Job
            include Formats

            attr_reader :job, :params
            attr_accessor :serialization_options

            def initialize(job, params = {})
              @job = job
              @params = params
              @serialization_options = {}
            end

            def data
              {
                'job' => job_data,
                'commit' => commit_data,
              }
            end

            private

              def job_data
                data = {
                  'id' => job.id,
                  'repository_id' => job.repository_id,
                  'repository_slug' => job.repository.slug,
                  'stage_id' => job.stage_id,
                  'build_id' => job.source_id,
                  'commit_id' => job.commit_id,
                  'number' => job.number,
                  'config' => job.obfuscated_config.stringify_keys,
                  'state' => job.state.to_s,
                  'started_at' => format_date(job.started_at),
                  'finished_at' => format_date(job.finished_at),
                  'queue' => job.queue,
                  'allow_failure' => job.allow_failure,
                  'tags' => job.tags,
                }
                data['log_id'] = job.log_id if include_log_id?
                data
              end

              def commit_data
                {
                  'id' => commit.id,
                  'sha' => commit.commit,
                  'branch' => commit.branch,
                  'branch_is_default' => branch_is_default(commit, repository),
                  'tag' => commit.tag_name,
                  'message' => commit.message,
                  'committed_at' => format_date(commit.committed_at),
                  'author_name' => commit.author_name,
                  'author_email' => commit.author_email,
                  'committer_name' => commit.committer_name,
                  'committer_email' => commit.committer_email,
                  'compare_url' => commit.compare_url,
                }
              end

              def branch_is_default(commit, repository)
                repository.default_branch == commit.branch
              end

              def commit
                job.commit
              end

              def repository
                job.repository
              end

              def include_log_id?
                !!serialization_options[:include_log_id]
              end
          end

          class Test < Job
          end
        end
      end
    end
  end
end
