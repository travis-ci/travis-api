module Travis
  module Api
    module V2
      module Http
        class Requests
          include Formats
          attr_reader :requests, :commits, :options

          def initialize(requests, options = {})
            @requests = requests
            @commits = requests.map(&:commit)
            @options = options
          end

          def data
            {
              'requests' => requests.map { |request| request_data(request) },
              'commits' => commits.compact.map { |commit| commit_data(commit) }
            }
          end

          private

            def request_data(request)
              {
                'id' => request.id,
                'repository_id' => request.repository_id,
                'commit_id' => request.commit_id,
                'created_at' => format_date(request.created_at),
                'owner_id' => request.owner_id,
                'owner_type' => request.owner_type,
                'event_type' => request.event_type,
                'base_commit' => request.base_commit,
                'head_commit' => request.head_commit,
                'result' => request.result,
                'message' => request.message,
                'pull_request' => request.pull_request?,
                'pull_request_number' => request.pull_request_number,
                'pull_request_title' => request.pull_request_title,
                'branch' => request.branch_name,
                'tag' => request.tag_name
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
                'pull_request_number' => commit.pull_request_number
              }
            end
        end
      end
    end
  end
end
