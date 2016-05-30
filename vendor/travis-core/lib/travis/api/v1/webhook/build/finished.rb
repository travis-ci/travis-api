module Travis
  module Api
    module V1
      module Webhook
        class Build
          class Finished < Build
            require 'travis/api/v1/webhook/build/finished/job'

            include Formats

            def data
              data = {
                'id' => build.id,
                'repository' => repository_data,
                'number' => build.number,
                'config' => build.obfuscated_config.stringify_keys,
                'status' => build.result,
                'result' => build.result,
                'status_message' => result_message,
                'result_message' => result_message,
                'started_at' => format_date(build.started_at),
                'finished_at' => format_date(build.finished_at),
                'duration' => build.duration,
                'build_url' => build_url,
                'commit_id' => commit.id,
                'commit' => commit.commit,
                'base_commit' => request.base_commit,
                'head_commit' => request.head_commit,
                'branch' => commit.branch,
                'message' => commit.message,
                'compare_url' => commit.compare_url,
                'committed_at' => format_date(commit.committed_at),
                'author_name' => commit.author_name,
                'author_email' => commit.author_email,
                'committer_name' => commit.committer_name,
                'committer_email' => commit.committer_email,
                'matrix' => build.matrix.map { |job| Job.new(job, options).data },
                'type'  => build.event_type,
                'state' => build.state.to_s,
                'pull_request' => build.pull_request?,
                'pull_request_number' => build.pull_request_number,
                'pull_request_title' => build.pull_request_title,
                'tag' => request.tag_name
              }

              if commit.pull_request?
                data['pull_request_number'] = commit.pull_request_number
              end

              data
            end

            def repository_data
              {
                'id' => repository.id,
                'name' => repository.name,
                'owner_name' => repository.owner_name,
                'url' => repository.url
              }
            end

            def result_message
              @result_message ||= ::Build::ResultMessage.new(build).short
            end
          end
        end
      end
    end
  end
end
