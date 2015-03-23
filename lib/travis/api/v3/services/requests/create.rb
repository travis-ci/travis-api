module Travis::API::V3
  class Services::Requests::Create < Service
    TIME_FRAME = 1.hour
    LIMIT      = 10
    private_constant :TIME_FRAME, :LIMIT

    result_type :request

    def run
      raise LoginRequired                              unless access_control.logged_in? or access_control.full_access?
      raise NotFound                                   unless repository = find(:repository)
      raise PushAccessRequired, repository: repository unless access_control.writable?(repository)

      user      = find(:user) if access_control.full_access? and params_for? 'user'.freeze
      user    ||= access_control.user
      remaining = remaining_requests(repository)

      raise RequestLimitReached, repository: repository if remaining == 0

      payload = query.schedule(repository, user)
      accepted(remaining_requests: remaining, repository: repository, request: payload)
    end

    def remaining_requests(repository)
      return LIMIT if access_control.full_access?
      count = query(:requests).count(repository, TIME_FRAME)
      count > LIMIT ? 0 : LIMIT - count
    end
  end
end
