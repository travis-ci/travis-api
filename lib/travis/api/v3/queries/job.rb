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

      payload = { id: id, user_id: user.id, source: 'api', reason: "Job Cancelled manually by User with id: #{user.login}" }
      service = Travis::Enqueue::Services::CancelModel.new(user, { job_id: id })
      service.push("job:cancel", payload)
      payload
    end

    def restart(user)
      raise JobAlreadyRunning if %w(received queued started).include? find.state

      service = Travis::Enqueue::Services::RestartModel.new(user, { job_id: id })
      payload = { id: id, user_id: user.id, restarted_by: user.id }

      service.push("job:restart", payload)
    end
  end
end
