module Travis::API::V3
  class Services::Caches::Delete < Service
    params :match, :branch

    def run!
      repo = find(:repository)
      return repo_migrated if migrated?(repo)

      result query.delete(repo)
    end
  end
end
