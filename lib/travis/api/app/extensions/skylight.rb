require 'travis/api/app'
require 'skylight'

class Travis::Api::App
  module Extensions
    module Skylight
      def route(verb, path, *)
        condition do
          trace = ::Skylight::Instrumenter.instance.current_trace
          endpoint = settings.name.to_s.split("::", 5).last.gsub(/::/, "/").downcase
          trace.endpoint = "#{verb} /#{endpoint}#{path}"
        end

        super
      end
    end
  end
end
