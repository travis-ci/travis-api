module Travis::API::V3
  class Services::Executions::ForOwner < Service
    params :page, :per_page, :from, :to
    result_type :executions

    def run!
      raise MethodNotAllowed if Travis.config.org?
      raise LoginRequired unless access_control.logged_in?

      owner = query(:owner).find

      raise NotFound unless owner
      raise InsufficientAccess unless access_control.visible?(owner)

      results = query(:executions).for_owner(owner, access_control.user.id, params['page'] || 0,
                                          params['per_page'] || 0, params['from'], params['to'])
      result presented_results(results)
    end

    def presented_results(results)
      senders = Travis::API::V3::Models::User.where(id: results.map(&:sender_id)).index_by(&:id)
      repositories = Travis::API::V3::Models::Repository.where(id: results.map(&:repository_id)).index_by(&:id)
      
      results.map do |execution|
        execution.sender_login = senders[execution.sender_id]&.login || 'Unknown Sender'
        if execution.sender_id == 0
          job = Job.find(execution.job_id)
          if job&.source_type == 'Build'
            request = Build.find(job.source_id)&.request
            execution.sender_login = 'cron' if request&.event_type == 'cron'
          end
        end
        repo = repositories[execution.repository_id]
        execution.repo_slug = repo&.slug || 'Unknown Repository'
        execution.repo_owner_name = repo&.owner_name || 'Unknown Repository Owner'

        execution
      end
    end
  end
end
