module Travis::API::V3
  class Queries::Caches < RemoteQuery
    params :branch, :match

    def find(repo)
      @repo = repo
      caches = fetch
      filter Models::Cache.factory(caches, repo)
    end

    def delete(repo)
      puts"**********"
      puts "now deleting"
      caches = find(repo)
      puts "caches: #{caches.each {|c| puts c}}"
      remove(caches)
    end

    def filter(list)
      puts"**********"
      puts "now filtering with #{params} params"
      puts match if match
      return list unless match
      list.select{|c| c.name.include? match}
    end

    private

    def prefix
      prefix = "#{@repo.github_id}/"
      prefix << branch << '/' if branch
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
