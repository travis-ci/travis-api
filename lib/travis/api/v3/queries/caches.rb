module Travis::API::V3
  class Queries::Caches < RemoteQuery
    params :branch, :match

    def find(repo)
      @repo = repo
      caches = fetch
      filter Models::Cache.factory(caches, repo)
    end

    def delete(repo)
      caches = find(repo)
      remove(caches)
    end

    def filter(list)
      return list unless match
      list.select{|c| c.name.include? match}
    end

    private

    def prefix
      prefix = "#{@repo.github_id}/"
      prefix << branch << '/' if branch
      prefix
    end

    def s3_config
      config[:cache_options][:s3] || {}
    end

    def gcs_config
      config[:cache_options][:gcs] || {}
    end
  end
end
