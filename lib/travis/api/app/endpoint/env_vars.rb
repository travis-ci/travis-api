require 'travis/api/app'
require 'travis/api/app/endpoint/setting_endpoint'

class Travis::Api::App
  class Endpoint
    class EnvVars < SettingsEndpoint
      define_method(:name) { :env_vars }
      define_routes!

      def update
        data = JSON.parse(request.body.read)[singular_name]
        disallow_migrating!(record.repository)

        previously_public = record.public?
        record.update(data)

        # if we update from private to public reset value
        if !previously_public && record.public? && data['value'].nil?
          record.value = nil
        end

        if record.valid?
          repo_settings.save
          respond_with(record, type: singular_name, version: :v2)
        else
          status 422
          respond_with(record, type: :validation_error, version: :v2)
        end
      end



      def respond_with(resource, options = {})
        result = respond(resource, options)

        parent_key = 'env_var'

        if result.is_a?(Hash)
          if !result.key?(:message) && !result.key?(:errors)
            result = result[parent_key.to_s] || result[parent_key.to_sym] ? result : { "#{parent_key}" => result }.symbolize_keys
          end
        else
          parent_key = 'env_vars' if result.is_a?(Enumerable)
          result = { "#{parent_key}" => result }.symbolize_keys
        end

        halt result || 404
      end

    end
  end
end
