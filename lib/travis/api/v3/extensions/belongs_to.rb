module Travis::API::V3
  module Extensions
    # This is a patch to ActiveRecord to allow classes for polymorphic relations to be nested in a module without the
    # module name being part of the type field.
    #
    # Example:
    #
    #     # Without this patch
    #     Repository.find(2).owner.class                          # => User
    #     Travis::API::V3::Models::Repository.find(2).owner.class # => User
    #
    #     # With this patch
    #     Repository.find(2).owner.class                          # => User
    #     Travis::API::V3::Models::Repository.find(2).owner.class # => Travis::API::V3::Models::User
    #
    # ActiveRecord does not support this out of the box. We accomplish this feature by tracking polymorphic relations
    # and then adding the namespace when calling ActiveRecord::Base#[] with the foreign type key and removing it again
    # in ActiveRecord::Base#[]=, so we don't break other code by accidentally writing the prefixed version to the
    # database.
    module BelongsTo
      class BaseClass
        attr_reader :name
        def initialize(klass)
          @name = klass.polymorphic_name
        end
      end

      module ClassMethods
        def polymorfic_foreign_types
          @polymorfic_foreign_types ||= []
        end

        def belongs_to(field, **options)
          polymorfic_foreign_types << (options[:foreign_type] || "#{field}_type") if options[:polymorphic]
          super
        end

        def base_class
          return super unless caller_locations.first.base_label == 'add_constraints'.freeze
          @base_class ||= BaseClass.new(super)
        end

        def polymorphic_name
          @polymorfic_name ||= name.sub("#{module_parent}::", ''.freeze)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
        super
      end

      def [](key)
        value   = super
        value &&= "#{self.class.module_parent}::#{value}" if self.class.polymorfic_foreign_types.include?(key)
        value
      end

      def []=(key, value)
        value &&= value.sub("#{self.class.module_parent}::", ''.freeze) if self.class.polymorfic_foreign_types.include?(key)
        super(key, value)
      end
    end
  end
end
