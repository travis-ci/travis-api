module Travis::API::V3
  class Queries::Build < Query
    params :id

    def find
      return Models::Build.find_by_id(id) if id
      raise WrongParams, 'missing build.id'.freeze
    end

    def cancel(user)
      payload = { id: id, user_id: user.id, source: 'api' }
      perform_async(:build_cancellation, payload)
      payload
    end

    def restart(user)
      payload = { id: id, user_id: user.id, source: 'api' }
      perform_async(:build_restart, payload)
      payload
    end
  end
end
