require 'travis/services/registry'

module Travis
  module Services
    module Helpers
      def run_service(key, *args)
        service(key, *args).run
      end

      def service(key, *args)
        params = args.last.is_a?(Hash) ? args.pop : {}
        user = args.last
        user ||= current_user if respond_to?(:current_user)
        Travis.services[key].new(user, params)
      end
    end
  end

  extend Services::Helpers
end
