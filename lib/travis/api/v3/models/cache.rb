module Travis::API::V3
  class Models::Cache
    attr_accessor :repo, :repository_id, :size, :name, :branch, :last_modified, :source, :key

    def self.factory(caches, repo)
      caches.map do |c|
        new(c, repo)
      end
    end

    def initialize(cache, repo)
      @repo = repo
      @repository_id = repo.id
      @size = Integer(cache.content_length)
      @name = cache.name.to_s.split('/').last
      @branch =  cache.key[%r{^(.*)/(.*)/[^/]+$}, 2]
      @last_modified = cache.last_modified
      @source = cache.source
      @key = cache.key
    end
  end
end
