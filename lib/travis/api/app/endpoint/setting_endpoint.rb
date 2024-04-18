class Travis::Api::App
  class SettingsEndpoint < Endpoint
    include ActiveSupport::Callbacks
    extend ActiveSupport::Concern

    set(:prefix) { "/settings/" << name[/[^:]+$/].underscore }

    class << self
      # This method checks if class based on a given name exists or creates
      # a new SettingsEndpoint subclass, which will be then used as an endpoint
      def subclass(name)
        class_name = name.to_s.camelize
        if Travis::Api::App::Endpoint.const_defined?(class_name)
          Travis::Api::App::Endpoint.const_get(class_name)
        else
          klass = create_settings_class(name)
          Travis::Api::App::Endpoint.const_set(class_name, klass)
          klass
        end
      end

      def create_settings_class(name)
        Class.new(self) do
          define_method(:name) { name }
          before { authenticate_by_mode! }
          define_routes!
        end
      end

      def define_routes!
        get("/", scope: :private) do index end
        get("/:id", scope: :private) do show end
        post("/", scope: :private) do create end
        patch("/:id", scope: :private) do update end
        delete("/:id", scope: :private) do destroy end
      end
    end

    # Rails style methods for easy overriding
    def index

      auth_for_repo(repo.id, 'repository_settings_read') unless Travis.config.legacy_roles

      respond_with(collection, type: name, version: :v2)
    end

    def show
      auth_for_repo(repo.id, 'repository_settings_read') unless Travis.config.legacy_roles

      respond_with(record, type: singular_name, version: :v2)
    end

    def update

      auth_for_repo(repo.id, 'repository_settings_update') unless Travis.config.legacy_roles

      disallow_migrating!(repo)

      record.update(JSON.parse(request.body.read)[singular_name])

      if record.valid?
        @changes = {
          env_vars: {
            created: "name: #{record.name}, is_public: #{record.public}, branch: #{record.branch || 'all'} "
          }
        } if is_env_var?

        repo_settings.save
        save_audit if is_env_var?

        respond_with(record, type: singular_name, version: :v2)
      else
        status 422
        respond_with(record, type: :validation_error, version: :v2)
      end
    end

    def create

      auth_for_repo(repo.id, 'repository_settings_create') unless Travis.config.legacy_roles

      disallow_migrating!(repo)

      record = collection.create(JSON.parse(request.body.read)[singular_name])

      if record.valid?
        @changes = {
          env_vars: {
            created: "name: #{record.name}, is_public: #{record.public}, branch: #{record.branch || 'all'}"
          }
        } if is_env_var?

        repo_settings.save
        save_audit if is_env_var?

        respond_with(record, type: singular_name, version: :v2)
      else
        status 422
        respond_with(record, type: :validation_error, version: :v2)
      end
    end

    def destroy
      auth_for_repo(repo.id, 'repository_settings_delete') unless Travis.config.legacy_roles

      disallow_migrating!(repo)

      record = collection.destroy(params[:id]) || record_not_found
      @changes = {
        env_vars: {
          destroyed: "name: #{record.name}, is_public: #{record.public}, branch: #{record.branch || 'all'} "
        }
      } if is_env_var?

      repo_settings.save
      save_audit if is_env_var?

      respond_with(record, type: singular_name, version: :v2)
    end

    def singular_name
      name.to_s.singularize
    end

    def collection
      @collection ||= repo_settings.send(name)
    end

    def repo
      @repo = Repository.find(params[:repository_id])
    end

    # This method can't be called "settings" because it clashes with
    # Sinatra's method
    def repo_settings
      @settings ||= begin
                      service(:find_repo_settings, id: params['repository_id'].to_i).run
                    end || halt(404, error: "Couldn't find repository")
    end

    def record
      collection.find(params[:id]) || record_not_found
    end

    def record_not_found
      halt(404, { error: "Could not find a requested setting" })
    end

    def changes
      @changes
    end

    def is_env_var?
      singular_name == 'env_var'
    end

    private

    def save_audit
      change_source = access_token.app_id == 2 ? 'admin-v2' : 'travis-api'
      Travis::API::V3::Models::Audit.create!(
        owner: current_user,
        change_source: change_source,
        source: @repo,
        source_changes: {
          settings: self.changes
        }
      )
      @changes = {}
    end
  end
end
