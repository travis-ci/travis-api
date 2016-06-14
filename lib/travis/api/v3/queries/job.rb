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
      if Travis::Features.owner_active?(:enqueue_to_hub, user)
        service = Travis::Enqueue::Services::CancelModel.new(user, payload)
        service.push
      else
        perform_async(:job_cancellation, payload)
      end
      payload
    end

    def restart(user)
      raise JobAlreadyRunning if %w(received queued started).include? find.state
      payload = { id: id, user_id: user.id, source: 'api' }
      perform_async(:job_restart, payload)
      payload
    end
  end
end
