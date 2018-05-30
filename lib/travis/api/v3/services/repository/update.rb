module Travis::API::V3
  class Services::Repository::Update < Service
    params :com_id, prefix: :repository

    def run!
      repository = check_login_and_find(:repository)
      raise InsufficientAccess unless access_control.full_access?
      query.update(com_id: params['com_id'])
      result repository
    end
  end
end
