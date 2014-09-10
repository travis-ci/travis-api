require 'travis/api/app'
require 'travis/api/app/endpoint/setting_endpoint'

class Travis::Api::App
  class Endpoint
    class EnvVars < SettingsEndpoint
      define_method(:name) { :env_vars }
      define_routes!

      def update
        data = JSON.parse(request.body.read)[singular_name]
        previously_public = record.public?
        record.update(data)

        # if we update from private to public reset value
        if !previously_public && record.public?
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

    end
  end
end
