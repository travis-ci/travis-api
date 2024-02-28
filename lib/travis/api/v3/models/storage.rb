require 'redis'

module Travis::API::V3
  class Models::Storage

    attr_reader :id, :value

    def initialize(attrs)
      @id = attrs.fetch(:id)
      @value = attrs[:value]
    end

    def public?
      true
    end

    def get
      @value = Travis.redis.get(id) || 0
      self
    end

    def create
      Travis.redis.set(id, value)
      self
    end

    def delete
      Travis.redis.del(id)
      @value = 0
      self
    end
  end
end
