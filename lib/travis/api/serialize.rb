require 'travis/api/serialize/formats'
require 'travis/api/serialize/v0'
require 'travis/api/serialize/v1'

module Travis
  module Api
    module Serialize
      DEFAULT_VERSION = 'v2'

      class << self
        def data(resource, options = {})
          new(resource, options).data
        end

        def builder(resource, options = {})
          Travis.logger.debug("#{self.class.name}#builder resource=#{resource.inspect} options=#{options.inspect}")
          target  = (options[:for] || 'http').to_s.camelize
          version = (options[:version] || default_version(options)).to_s.camelize
          type    = (options[:type] || type_for(resource)).to_s.camelize.split('::')
          ([version, target] + type).inject(self) do |const, name|
            Travis.logger.debug("#{self.class.name}#builder inject const=#{const.inspect} name=#{name.inspect}")
            begin
              if const && const.const_defined?(name.to_s.camelize, false)
                const.const_get(name, false)
              else
                nil
              end
            rescue NameError
              nil
            end
          end
        end

        def new(resource, options = {})
          builder = builder(resource, options) || raise(ArgumentError, "cannot serialize #{resource.inspect}, options: #{options.inspect}")
          builder.new(resource, options[:params] || {})
        end

        private

          def type_for(resource)
            Travis.logger.debug("#{self.class.name}#type_for in resource=#{resource.inspect}")
            if arel_relation?(resource)
              type = resource.klass.name.pluralize
            else
              type = resource.class
              type = type.base_class if active_record?(type)
              type = type.name
            end
            type.split('::').last.tap do |value|
              Travis.logger.debug("#{self.class.name}#type_for out value=#{value.inspect}")
            end
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
