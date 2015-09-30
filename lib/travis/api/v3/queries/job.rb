module Travis::API::V3
  class Queries::Job < Query
    params :id

    def find
      return Models::Job.find_by_id(id) if id
      raise WrongParams, 'missing job.id'.freeze
    end

    def cancel(user)
      payload = { id: id, user_id: user.id, source: 'api' }
      perform_async(:job_cancellation, payload)
      payload
    end

    def restart(user)
      payload = { id: id, user_id: user.id, source: 'api' }
      perform_async(:job_restart, payload)
      payload
    end
  end
end
