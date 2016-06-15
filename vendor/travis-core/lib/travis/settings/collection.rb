class Travis::Settings
  class Collection
    include Enumerable

    delegate :each, :<<, :push, :delete, :length, :first, :last, to: '@collection'
    attr_accessor :additional_attributes

    class << self
      # This feels a bit weird, but I don't know how to do it better.
      # Virtus checks for collection type by checking an array member,
      # so if you pass Array[String], a collection type will be set to String.
      # Here, we already specify what is a model class for a collection.
      # In order to not have to specify class twice, I created this method
      # which creates just what Virtus needs.
      def for_virtus
        self[model_class]
      end

      def [](*args)
        new(*args)
      end

      def model(model_name_or_class = nil)
        if model_name_or_class
          klass = if model_name_or_class.is_a?(String) || model_name_or_class.is_a?(Symbol)
            name = model_name_or_class.to_s.classify
            self.const_defined?(name, false) ? self.const_get(name, false) : Travis::Settings.const_get(name, false)
          else
            model_name_or_class
          end

          @model_class = klass
        else
          @model_class
        end
      end
      attr_reader :model_class
    end

    delegate :model_class, to: 'self.class'

    def initialize(*args)
      @collection = Array[*args]
    end

    def create(attributes)
      model = model_class.new(attributes)
      model.load({}, additional_attributes)
      model.id = SecureRandom.uuid unless model.id
      push model
      model
    end

    def find(id)
      detect { |model| model.id == id.to_s }
    end

    def destroy(id)
      record = find(id)
      if record
        delete record
        record
      end
    end

    def to_hash
      @collection.map(&:to_hash)
    end

    def load(collection, additional_attributes = {})
      self.additional_attributes = additional_attributes
      return unless collection.respond_to?(:each)

      collection.each do |element|
        self.push model_class.load(element, additional_attributes)
      end
    end
  end
end
