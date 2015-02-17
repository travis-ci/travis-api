module Travis::API::V3
  class Queries::Requests < Query
    def schedule_for(repository)
      perform_async(:build_request, type: 'api'.freeze, payload: payload, credentials: {})
    end

    def find(repository)
    end

    def payload
      raise NotImplementedError
    end
  end
end
