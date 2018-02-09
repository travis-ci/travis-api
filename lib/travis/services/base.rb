require 'travis/services/helpers'

module Travis
  module Services
    class Base
      class << self
        def register(key)
          Travis.services.add(key, self)
        end

        def scope_access!
          @scope_access = true
        end

        def scope_access?
          self.name
          !!@scope_access
        end
      end

      include Helpers

      attr_reader :current_user, :params

      def initialize(*args)
        @params = args.last.is_a?(Hash) ? args.pop.symbolize_keys : {}
        @current_user = args.last
      end

      def scope(key)
        scope = key.to_s.camelize.constantize
        scope = scope.viewable_by(current_user) if self.class.scope_access?
        scope
      end

      def logger
        Travis.logger
      end
    end
  end
end
