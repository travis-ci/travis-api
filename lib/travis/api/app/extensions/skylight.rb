require 'logger'
require 'skylight'
require 'travis/api/app'

class Travis::Api::App
  module Extensions
    module Skylight
      def self.registered(base)
        config = ::Skylight::Config.load(nil, ENV['RACK_ENV'], ENV)
        config['root'] = base.root
        config['agent.sockfile_path'] = File.join(config['root'], 'tmp')
        config.logger = Logger.new(STDOUT)
        config.validate!

        ::Skylight.start!(config)

        base.use ::Skylight::Middleware
      end

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
