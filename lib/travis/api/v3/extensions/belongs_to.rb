module Travis::API::V3
  module Extensions
    module BelongsTo
      module ClassMethods
        def polymorfic_foreign_types
          @polymorfic_foreign_types ||= []
        end

        def belongs_to(field, options = {})
          polymorfic_foreign_types << (options[:foreign_type] || "#{field}_type") if options[:polymorphic]
          super
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
        super
      end

      def [](key)
        value   = super
        value &&= "#{self.class.parent}::#{value}" if self.class.polymorfic_foreign_types.include?(key)
        value
      end

      def []=(key, value)
        value &&= value.sub("#{self.class.parent}::") if self.class.polymorfic_foreign_types.include?(key)
        super(key, value)
      end
    end
  end
end
