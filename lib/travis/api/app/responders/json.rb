require 'travis/api/serialize'

class Travis::Api::App
  module Responders
    class Json < Base
      include Helpers::Accept

      def apply?
        Travis.logger.debug("#{self.class.name}#apply? resource=#{resource.inspect}")
        super && !resource.is_a?(String) && !resource.nil? && accepts_log?
      end

      instrument_method
      def apply
        super

        result
      end

      private

        def content_type
          'application/json;charset=utf-8'
        end

        def accepts_log?
          return true unless resource.is_a?(Log) || resource.is_a?(Travis::RemoteLog)

          if resource.is_a?(Log)
            Travis.logger.debug("#{self.class.name}#accepts_log? is_a?(Log)")
            chunked = accept_params[:chunked]
            if resource.removed_at
              true
            else
              chunked ? !resource.aggregated_at : true
            end
          elsif resource.is_a?(Travis::RemoteLog)
            Travis.logger.debug("#{self.class.name}#accepts_log? is_a?(Travis::RemoteLog)")
            resource.archived_at.nil?
          end
        end

        def result
          if builder
            p = params
            p[:root] = options[:root] if options[:root]
            p[:root] = options[:type] if options[:type] && !p[:root]
            builder.new(resource, p).data
          else
            basic_type_resource
          end
        end

        def builder
          if defined?(@builder)
            @builder
          else
            @builder = Travis::Api::Serialize.builder(resource, { :version => version }.merge(options))
          end
        end

        def accept_params
          (options[:accept].params || {}).symbolize_keys
        end

        def version
          options[:accept].version || Travis::Api::App::Helpers::Accept::DEFAULT_VERSION
        end

        def params
          (request.params || {}).merge(accept_params)
        end

        def basic_type_resource
          resource if resource.is_a?(Hash)
        end
    end
  end
end
