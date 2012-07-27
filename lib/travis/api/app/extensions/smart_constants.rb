require 'travis/api/app'

class Travis::Api::App
  module Extensions
    # Allows writing
    #
    #   helpers :some_helper
    #
    # Instead of
    #
    #   helpers Travis::Api::App::Helpers::SomeHelper
    module SmartConstants
      def helpers(*list, &block)
        super(*resolve_constants(list, Helpers), &block)
      end

      def register(*list, &block)
        super(*resolve_constants(list, Extensions), &block)
      end

      private

        def resolve_constants(list, namespace)
          list.map { |e| Symbol === e ? namespace.const_get(e.to_s.camelize) : e }
        end
    end
  end
end
