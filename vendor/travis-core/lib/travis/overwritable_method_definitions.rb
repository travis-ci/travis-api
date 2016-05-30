module Travis
  # OverwritableMethodDefinitions module allows to easily define methods which will be
  # overwritable in the same class. For example, given such a class:
  #
  #   class Foo
  #     include Travis::OverwritableMethodDefinitions
  #
  #     define_overwritable_method :foo do
  #       'foo'
  #     end
  #
  #     def foo
  #       super + '!'
  #     end
  #   end
  #
  #   Foo.new.foo #=> foo!
  module OverwritableMethodDefinitions
    def self.included(base)
      base.extend(ClassMethods)
      base.initialize_overwritable_methods_module
    end

    module ClassMethods
      def inherited(child)
        child.initialize_overwritable_methods_module
      end

      def initialize_overwritable_methods_module
        @generated_overwritable_methods = Module.new
        include @generated_overwritable_methods
      end

      def define_overwritable_method(*args, &block)
        @generated_overwritable_methods.send :define_method, *args, &block
      end
    end
  end
end
