module Travis::API::V3
  class Services::Requests::Create < Service
    result_type :request

    def run
      raise LoginRequired                              unless access_control.logged_in? or access_control.full_access?
      raise NotFound                                   unless repository = find(:repository)
      raise PushAccessRequired, repository: repository unless access_control.writable?(repository)

      user   = find(:user) if access_control.full_access? and params_for? 'user'.freeze
      user ||= access_control.user

      query.schedule(repository, user)
      accepted(:request)
    end
  end
end
