module Travis::API::V3
  class Queries::Caches < RemoteQuery

    def find(repo)
      caches = fetch
      Models::Cache.factory(caches, repo)
    end

    #might want this for branch name and slug
    def filter(list)
      # sort list
      list
    end
  end
end
