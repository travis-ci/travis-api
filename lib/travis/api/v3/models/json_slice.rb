module Travis::API::V3
  class Models::JsonSlice
    include Enumerable
    include Virtus.model

    attr_reader :parent, :attr

    def self.pair(klass)
      @@pair = klass
    end

    def pair
      self.class.class_variable_get(:@@pair)
    end

    def each(&block)
      return enum_for(:each) unless block_given?
      attributes.keys.each { |name| yield read(name) }
      self
    end

    def read(name)
      value = send(name)
      pair.new(name, value, parent) unless value.nil?
    end

    def update(name, value)
      send(:"#{name}=", value)
      @sync.call if @sync
      read(name)
    end

    def to_h
      Hash[map { |x| [x.name, x.value] }]
    end

    def to_json
      to_h.to_json
    end

    def parent_attr(parent, attr)
      @parent, @attr = parent, attr
      @sync = -> do
        @parent.send(:"#{@attr}=", to_json)
        @parent.save!
      end
    end
  end
end
