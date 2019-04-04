module Travis::API::V3
  class Services::Repository::Update < Service
    params :com_id, prefix: :repository

    def run!
      repository = check_login_and_find(:repository)
      raise InsufficientAccess unless access_control.full_access?
      return repo_migrated if migrated?(repository)

      query.update(attrs)
      result repository
    end

    def attrs
      {
        com_id: params['com_id'],
        active: !!params['active']
      }
    end
  end
end
