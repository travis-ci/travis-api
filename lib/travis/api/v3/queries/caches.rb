module Travis::API::V3
  class Queries::Caches < RemoteQuery
    params :name, :branch

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
      return list unless name
      list.select{|c| c.name.include? name}
    end

    private

    def prefix
      branch += '/' unless branch.to_s.empty?
      "#{@repo.github_id.to_s}/#{branch}"
    end

    def s3_config
      config[:cache_options][:s3] || {}
    end

    def gcs_config
      config[:cache_options][:gcs] || {}
    end
  end
end
