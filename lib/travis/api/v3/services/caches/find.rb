module Travis::API::V3
  class Services::Caches::Find < Service
    params :match, :branch

    def run!
      puts "DEBUG: Services::Caches::Find.run!"
      repo = check_login_and_find(:repository)
      puts "DEBUG: Services::Caches::Find.run! - Repository: #{repo}"
      access_control.permissions(repo).cache_view! unless Travis.config.legacy_roles

      raise InsufficientAccess unless access_control.user.permission?(:push, repository_id: repo.id)
      r = result query.find(repo)
      puts "DEBUG: Services::Caches::Find.run! - Result: #{r}"
      r
    end
  end
end
