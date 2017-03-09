module Travis::API::V3
  class Queries::Caches < RemoteQuery
    params :name, :branch, :match

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

    # def prefix
    #   "#{@repo.github_id.to_s}/#{branch}"
    # end
    def prefix
      prefix = "#{@repo.github_id}/"
      prefix << branch << '/' if branch
      prefix << match << '/' if match
      puts "*********************************"
      puts prefix
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
