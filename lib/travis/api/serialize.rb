require 'travis/api/serialize/formats'
require 'travis/api/serialize/v0'
require 'travis/api/serialize/v1'
require 'travis/honeycomb'

module Travis
  module Api
    module Serialize
      DEFAULT_VERSION = 'v2'

      class << self
        def data(resource, options = {})
          new(resource, options).data
        end

        def builder(resource, options = {})
          target  = (options[:for] || 'http').to_s.camelize
          version = (options[:version] || default_version(options)).to_s
          type    = options[:type] || type_for(resource)

          Travis::Honeycomb.context.add('api_version', version.downcase)

          version = 'v2' if version.start_with?('v2.')
          parts = [version, target] + type.to_s.split('::')
          parts = parts.map { |part| part.to_s.camelize }
          parts.inject(self) do |const, name|
            begin
              if const && const.const_defined?(name, false)
                const.const_get(name, false)
              else
                 puts "Could not find serialize builder for #{version} #{target} #{type}" unless [['Hash'], ['RemoteLog']].include?(type)
                nil
              end
            rescue NameError
               puts "Could not find serialize builder for #{version} #{target}" unless [['Hash'], ['RemoteLog']].include?(type)
              nil
            end
          end
        end

        def new(resource, options = {})
          builder = builder(resource, options)
          if !builder 
              raise(ArgumentError, "cannot serialize #{resource.inspect}, options: #{options.inspect}")
          end
          builder.new(resource, options[:params] || {})
        end

        private

          def type_for(resource)
            if arel_relation?(resource)
              type = resource.klass.name.pluralize
            else
              type = resource.class.name
            end
            type.split('::').last
          end

          def arel_relation?(object)
            object.respond_to?(:klass)
          end

          def active_record?(object)
            object.respond_to?(:base_class)
          end

          def default_version(options)
            if options[:for].to_s.downcase == "pusher"
              "v0"
            else
              DEFAULT_VERSION
            end
          end
      end
    end
  end
end
