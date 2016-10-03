module Travis::API::V3
  class Models::Cache
    attr_accessor :repo, :repository_id, :size, :slug, :branch, :last_modified

    def self.factory(caches, repo)
      caches.map do |c|
        new(c, repo)
      end
    end

    def initialize(cache, repo)
      @repo = repo
      @repository_id = repo.id
      @size = Integer(cache.content_length)
      @slug = cache.key.to_s.split('/').last
      @branch =  cache.key[%r{^\d+/(.*)/[^/]+$}, 1]
      @last_modified = cache.last_modified
    end
  end
end
