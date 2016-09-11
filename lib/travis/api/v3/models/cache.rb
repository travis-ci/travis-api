module Travis::API::V3
  class Models::Cache
    attr_accessor :repo, :repository_id, :size, :branch, :last_modified

    def self.new(caches, repo)
      caches.map do |c|
        super(c, repo)
      end
    end

    def initialize(cache, repo)
      @repo = repo
      @repository_id = repo.id,
      @size = Integer(cache.content_length),
      @branch =  cache.key[%r{^\d+/(.*)/[^/]+$}, 1],
      @last_modified = cache.last_modified
    end
  end
end
