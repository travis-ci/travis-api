require 'travis/api/app'
require 'travis/api/app/endpoint/setting_endpoint'

class Travis::Api::App
  class SingletonSettingsEndpoint < SettingsEndpoint
    class << self
      def create_settings_class(name)
        klass = Class.new(self) do
          define_method(:name) { name }
          get("/", scope: :private) do show end
          patch("/", scope: :private) do update end
          delete("/", scope: :private) do destroy end
        end
      end
    end

    def update
      record = parent.update(name, JSON.parse(request.body.read)[singular_name])
      if record.valid?
        repo_settings.save
        respond_with(record, type: singular_name, version: :v2)
      else
        status 422
        respond_with(record, type: :validation_error, version: :v2)
      end
    end

    def destroy
      record = parent.delete(name)
      repo_settings.save
      respond_with(record, type: singular_name, version: :v2)
    end

    def record
      parent.get(name) || record_not_found
    end

    def parent
      repo_settings
    end

    def record_not_found
      halt(404, { error: "Could not find a requested setting" })
    end
  end
end
