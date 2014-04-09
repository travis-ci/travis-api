require 'skylight'
require 'travis/api/app'

class Travis::Api::App
  module Skylight
    class ServiceProbe
      class ServiceProxy < Delegator
        def initialize(key, service)
          super(service)
          @key = key
          @service = service
        end

        def __getobj__
          @service
        end

        def __setobj__(obj)
          @service = obj
        end

        def run(*args)
          opts = {
            category: "api.service.#{@key}",
            title: "Service #{@key}",
            annotations: {
              service: @key.to_s
            }
          }

          ::Skylight.instrument(opts) do
            @service.run(*args)
          end
        end
      end

      def install
        Travis::Services::Helpers.class_eval do
          alias service_without_sk service

          def service(key, *args)
            s = service_without_sk(key, *args)
            ServiceProxy.new(key, s)
          end
        end
      end
    end

    ::Skylight::Probes.register("Travis::Services::Helpers", "travis/services/helpers", ServiceProbe.new)
  end
end
