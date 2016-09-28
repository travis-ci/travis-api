module Travis::API::V3
  class Queries::Caches < RemoteQuery
    params :match, :branch

    def find(repo)
      caches = fetch(repo)
      Models::Cache.factory(caches, repo)
    end

    #might want this for branch name and slug
    def filter(list)
      # sort list
      list
    end

    private

    def s3_config
      config.cache_options.try(:s3) || {}
    end

    def gcs_config
      config.cache_options.try(:gcs) || {}
    end
  end
end
