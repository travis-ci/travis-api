require 'travis/api/enqueue/services/restart_model'
require 'travis/api/enqueue/services/cancel_model'

module Travis::API::V3
  class Queries::Job < Query
    params :id

    def find
      return Models::Job.find_by_id(id) if id
      raise WrongParams, 'missing job.id'.freeze
    end

    def cancel(user)
      raise JobNotCancelable if %w(passed failed canceled errored).include? find.state
      payload = { id: id, user_id: user.id, source: 'api' }
      #look for repo.owner instead and look if the user belongs to the repo, instead of using user for the feature flag
      if Travis::Features.owner_active?(:enqueue_to_hub, find.repository.owner)
        service = Travis::Enqueue::Services::CancelModel.new(user, { job_id: id })
        service.push("job:cancel", payload)
      else
        perform_async(:job_cancellation, payload)
      end
      payload
    end

    def restart(user)
      raise JobAlreadyRunning if %w(received queued started).include? find.state

      if Travis::Features.owner_active?(:enqueue_to_hub, find.repository.owner)
        service = Travis::Enqueue::Services::RestartModel.new(user, { job_id: id })
        payload = { id: id, user_id: user.id }
        service.push("job:restart", payload)
      else
        payload = { id: id, user_id: user.id, source: 'api' }
        perform_async(:job_restart, payload)
      end
      payload
    end
  end
end
