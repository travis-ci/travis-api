require_relative './json_sync'

module Travis::API::V3
  class Models::JsonSlice
    include Virtus.model, Enumerable, Models::JsonSync

    def self.child(klass)
      @@child_klass = klass
    end

    def child_klass
      @@child_klass
    end

    def each(&block)
      return enum_for(:each) unless block_given?
      attributes.keys.each { |id| yield read(id) }
      self
    end

    def read(name)
      value = send(name)
      child_klass.new(name, value, parent) unless value.nil?
    end

    def update(name, value)
      send(:"#{name}=", value)
      sync!
      read(name)
    end

    def to_h
      Hash[map { |x| [x.name, x.value] }]
    end
  end
end
