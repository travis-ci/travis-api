require 'skylight'
require 'travis/api/app'

class Travis::Api::App
  module Skylight
    class RedisProbe
      def install
        ::Redis::Client.class_eval do
          alias call_without_sk call

          def call(command_parts, &block)
            command   = command_parts[0].upcase

            opts = {
              category: "api.redis.#{command.downcase}",
              title:    "Redis #{command}",
                annotations: {
                command:   command.to_s
              }
            }

            ::Skylight.instrument(opts) do
              call_without_sk(command_parts, &block)
            end
          end
        end
      end
    end
    ::Skylight::Probes.register("Redis", "redis", RedisProbe.new)
  end
end
