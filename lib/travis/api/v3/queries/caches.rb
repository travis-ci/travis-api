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

    def main_type
      "cache"
    end

    private

    def prefix
      prefix = "#{@repo.vcs_id || @repo.github_id}/#{branch}"
      prefix << '/' unless prefix.last == '/'
      prefix
    end
  end
end
