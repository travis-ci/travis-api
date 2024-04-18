require 'travis/api/app'
require 'travis/api/app/endpoint/setting_endpoint'

class Travis::Api::App
  class SingletonSettingsEndpoint < SettingsEndpoint
    class << self
      def create_settings_class(name)
        klass = Class.new(self) do
          define_method(:name) { name }
          before { authenticate_by_mode! }
          get("/:repository_id", scope: :private) do show end
          patch("/:repository_id", scope: :private) do update end
          delete("/:repository_id", scope: :private) do destroy end
        end
      end
    end

    def update
      auth_for_repo(parent.repository.id, 'repository_settings_update') unless Travis.config.legacy_roles

      disallow_migrating!(parent.repository)

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
      auth_for_repo(parent.repository.id, 'repository_settings_delete') unless Travis.config.legacy_roles

      disallow_migrating!(parent.repository)

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
