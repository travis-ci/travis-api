require 'travis/api/serialize/formats'

module Travis
  module Api
    module Serialize
      module V2
        module Http
          class Build
            include Formats

            attr_reader :build, :params
            attr_accessor :serialization_options

            def initialize(build, params = {})
              @build = build
              @params = params
              @serialization_options = {}
            end

            def data
              Travis.logger.debug("#{self.class.name} params=#{params.inspect} serialization_options=#{serialization_options.inspect}")
              {
                'build'  => build_data
                'commit' => commit_data,
                'jobs'   => jobs_data,
                'annotations' => annotations_data
              }
            end

            private

              def build_data
                {
                  'id' => build.id,
                  'repository_id' => build.repository_id,
                  'commit_id' => build.commit_id,
                  'number' => build.number,
                  'event_type' => build.event_type,
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

              def commit_data
                {
                  'id' => commit.id,
                  'sha' => commit.commit,
                  'branch' => commit.branch,
                  'branch_is_default' => branch_is_default,
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
                  'state' => job.state.to_s,
                  'number' => job.number,
                  'config' => job.obfuscated_config.stringify_keys,
                  'started_at' => format_date(job.started_at),
                  'finished_at' => format_date(job.finished_at),
                  'queue' => job.queue,
                  'allow_failure' => job.allow_failure,
                  'tags' => job.tags,
                  'annotation_ids' => job.annotation_ids,
                }.tap do |ret|
                  ret['log_id'] = job.log_id if include_log_id?
                end
              end

              def jobs_data
                return [] unless params[:include_jobs]
                build.matrix.map { |job| job_data(job) }
              end

              def annotations_data
                return [] unless params[:include_jobs]
                Annotations.new(annotations, params).data["annotations"]
              end

              def branch_is_default
                repository.default_branch == commit.branch
              end

              def annotations
                build.matrix.map(&:annotations).flatten
              end

              def commit
                build.commit
              end

              def repository
                build.repository
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
