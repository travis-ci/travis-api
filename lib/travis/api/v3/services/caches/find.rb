module Travis::API::V3
  class Services::Caches::Find < Service
    params :match, :branch

    def run!
      repo = check_login_and_find(:repository)
      raise InsufficientAccess unless access_control.user.permission?(:push, repository_id: repo.id)
      result query.find(repo)
    end
  end
end
