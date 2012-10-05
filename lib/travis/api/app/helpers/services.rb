require 'travis/api/app'

class Travis::Api::App
  module Helpers
    module Services
      def all(params)
        service(services_namespace, :all, params)
      end

      def one(params)
        service(services_namespace, :one, params)
      end

      def update(params)
        service(services_namespace, :update, params)
      end

      private

        def services_namespace
          self.class.name.split('::').last
        end
    end
  end
end
