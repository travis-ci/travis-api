module Travis::API::V3
  class Services::Requests::Create < Service
    TIME_FRAME = 1.hour
    private_constant :TIME_FRAME

    result_type :request
    params "request", "user", :config, :message, :branch, :token

    def run
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless repository = find(:repository)
      access_control.permissions(repository).create_request!

      user      = find(:user) if access_control.full_access? and params_for? 'user'.freeze
      user    ||= access_control.user
      remaining = remaining_requests(repository)

      raise RequestLimitReached, repository: repository if remaining == 0

      payload = query.schedule(repository, user)
      accepted(remaining_requests: remaining, repository: repository, request: payload)
    end

    def limit(repository)
      if repository.settings.nil?
        Travis.config.requests_create_api_limit
      else
        repository.settings["api_builds_rate_limit"] || Travis.config.requests_create_api_limit
      end
    end

    def remaining_requests(repository)
      api_builds_rate_limit = limit(repository)
      return api_builds_rate_limit if access_control.full_access?
      count = query(:requests).count(repository, TIME_FRAME)
      count > api_builds_rate_limit ? 0 : api_builds_rate_limit - count
    end
  end
end
