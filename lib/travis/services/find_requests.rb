require 'core_ext/active_record/none_scope'

module Travis
  module Services
    class FindRequests < Base
      register :find_requests

      def run
        preload(result)
      end

      private

        def preload(requests)
          requests.includes(:commit, :builds)
        end

        def result
          if repo
            columns = %w/id repository_id commit_id created_at owner_id owner_type
                         event_type base_commit head_commit result message payload state/
            requests = repo.requests.select(columns.map { |c| %Q["requests"."#{c}"] })
            if params[:older_than]
              requests.older_than(params[:older_than])
            else
              requests.recent(requests_limit)
            end
          else
            raise Travis::RepositoryNotFoundError.new(params)
          end
        end

        def repo
          @repo ||= run_service(:find_repo, params)
        end

        def requests_limit
          max_limit = Travis.config.services.find_requests.max_limit
          default_limit = Travis.config.services.find_requests.default_limit
          if !params[:limit]
            default_limit
          elsif params[:limit] > max_limit
            max_limit
          else
            params[:limit]
          end
        end
    end
  end
end
