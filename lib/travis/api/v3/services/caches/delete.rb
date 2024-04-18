module Travis::API::V3
  class Services::Caches::Delete < Service
    params :match, :branch

    def run!
      repo = check_login_and_find(:repository)
      access_control.permissions(repo).cache_delete! unless Travis.config.legacy_roles

      raise InsufficientAccess unless access_control.user.permission?(:push, repository_id: repo.id)
      return repo_migrated if migrated?(repo)

      result query.delete(repo)
    end
  end
end
