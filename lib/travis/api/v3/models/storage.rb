require 'redis'

module Travis::API::V3
  class Models::Storage

    attr_reader :id, :value

    def initialize(attrs)
      puts "ATTRS: #{attrs.inspect}"
      @id = attrs.fetch(:id)
      @value = attrs[:value]
    end

    def public?
      true
    end

    def get
      puts "ID: #{id.inspect}, VAL: #{value.inspect}"
      @value = Travis.redis.get(id) || 0


      puts "ID: #{id.inspect}, VAL: #{value.inspect}"
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
