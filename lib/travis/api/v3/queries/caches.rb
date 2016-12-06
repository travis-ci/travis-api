module Travis::API::V3
  class Queries::Caches < RemoteQuery
    params :match, :branch

    def find(repo)
      @repo = repo
      caches = fetch
      filter Models::Cache.factory(caches, repo)
    end

    def delete(repo)
      @repo = repo
      destroyed_caches = remove
      filter Models::Cache.factory(destroyed_caches, repo)
    end

    def filter(list)
      return list unless match
      list.select{|c| c.slug.include? match}
    end

    private

    def prefix
      "#{@repo.github_id.to_s}/#{branch}"
    end

    def s3_config
      config.cache_options.try(:s3) || {}
    end

    def gcs_config
      config.cache_options.try(:gcs) || {}
    end
  end
end
