require 'travis/services/helpers'

module Travis
  module Services
    class Base
      def self.register(key)
        Travis.services.add(key, self)
      end

      include Helpers

      attr_reader :current_user, :params

      def initialize(*args)
        @params = args.last.is_a?(Hash) ? args.pop.symbolize_keys : {}
        @current_user = args.last
      end

      def scope(key)
        key.to_s.camelize.constantize
      end

      def logger
        Travis.logger
      end
    end
  end
end
