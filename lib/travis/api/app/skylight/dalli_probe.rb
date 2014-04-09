require 'skylight'
require 'travis/api/app'

class Travis::Api::App
  module Skylight
    class DalliProbe
      def install
        %w[get get_multi set add incr decr delete replace append prepend].each do |method_name|
          next unless Dalli::Client.method_defined?(method_name.to_sym)
          Dalli::Client.class_eval <<-EOD
            alias #{method_name}_without_sk #{method_name}
            def #{method_name}(*args, &block)
              ::Skylight.instrument(category: "api.memcache.#{method_name}", title: "Memcache #{method_name}") do
                #{method_name}_without_sk(*args, &block)
              end
            end
          EOD
        end
      end
    end

    ::Skylight::Probes.register("Dalli::Client", "dalli", DalliProbe.new)
  end
end
