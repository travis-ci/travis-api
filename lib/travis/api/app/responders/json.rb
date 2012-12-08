class Travis::Api::App
  module Responders
    class Json < Base
      include Helpers::Accept

      def apply?
        super && !resource.is_a?(String) && !resource.nil? && accepts_log?
      end

      def apply
        halt result.to_json if result
      end

      private

        def accepts_log?
          return true unless resource.is_a?(Log)

          chunked = accept_params[:chunked]
          chunked ? !resource.aggregated_at : true
        end

        def result
          builder ? builder.new(resource, params).data : basic_type_resource
        end

        def builder
          if defined?(@builder)
           @builder
          else
           @builder = Travis::Api.builder(resource, { :version => version }.merge(options))
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
