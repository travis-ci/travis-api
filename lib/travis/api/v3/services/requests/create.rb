module Travis::API::V3
  class Services::Requests::Create < Service
    TIME_FRAME = 1.hour
    LIMIT = 10
    private_constant :TIME_FRAME, :LIMIT

    result_type :request
    params "request", "user", :merge_mode, :config, :configs, :message, :branch, :sha, :token

    def run
      repository = check_login_and_find(:repository)
      return not_found if repository.owner.ro_mode?

      access_control.permissions(repository).create_request!
      return repo_migrated if migrated?(repository)

      raise RepositoryInactive.new(repository: repository) unless repository.active?

      user = find(:user) if access_control.full_access? and params_for? 'user'.freeze
      user ||= access_control.user
      max = limit(repository)
      remaining = remaining_requests(max, repository)

      raise RequestLimitReached.new(repository: repository, max_requests: max, per_seconds: TIME_FRAME.to_i) if remaining == 0

      payload = query.schedule(repository, user)
      accepted(remaining_requests: remaining, repository: repository, request: payload)
    end

    def limit(repository)
      repository.admin_settings.api_builds_rate_limit || Travis.config.requests_create_api_limit || LIMIT
    end

    def remaining_requests(api_builds_rate_limit, repository)
      return api_builds_rate_limit if access_control.full_access?
      count = query(:requests).count(repository, TIME_FRAME)
      count > api_builds_rate_limit ? 0 : api_builds_rate_limit - count
    end
  end
end
