require 'travis/api/serialize/v0/pusher/job/canceled'
require 'travis/api/serialize/v0/pusher/job/created'
require 'travis/api/serialize/v0/pusher/job/log'
require 'travis/api/serialize/v0/pusher/job/received'
require 'travis/api/serialize/v0/pusher/job/started'
require 'travis/api/serialize/v0/pusher/job/finished'

module Travis
  module Api
    module Serialize
      module V0
        module Pusher
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
              job_data(job).merge(
                'commit' => commit_data(job.commit)
              )
            end

            private

              def job_data(job)
                {
                  'id' => job.id,
                  'repository_id' => job.repository_id,
                  'repository_slug' => job.repository.slug,
                  'repository_private' => job.repository.private,
                  'build_id' => job.source_id,
                  'commit_id' => job.commit_id,
                  'number' => job.number,
                  'state' => job.state.to_s,
                  'started_at' => format_date(job.started_at),
                  'finished_at' => format_date(job.finished_at),
                  'queue' => job.queue,
                  'allow_failure' => job.allow_failure,
                  'annotation_ids' => job.annotation_ids
                }.tap do |ret|
                  ret['log_id'] = job.log_id if include_log_id?
                end
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

              def include_log_id?
                !!serialization_options[:include_log_id]
              end
          end
        end
      end
    end
  end
end
