require 'travis/api/app'

class Travis::Api::App
  class SettingsEndpoint < Endpoint
    set(:prefix) { "/settings/" << name[/[^:]+$/].underscore }

    class << self
      # This method checks if class based on a given name exists or creates
      # a new SettingsEndpoint subclass, which will be then used as an endpoint
      def subclass(name)
        class_name = name.to_s.camelize
        if Travis::Api::App.const_defined?(class_name)
          Travis::Api::App.const_get(class_name)
        else
          klass = create_settings_class(name)
          Travis::Api::App.const_set(class_name, klass)
          klass
        end
      end

      def create_settings_class(name)
        klass = Class.new(self) do
          define_method(:name) { name }
          get("/", scope: :private) do index end
          get("/:id", scope: :private) do show end
          post("/", scope: :private) do create end
          patch("/:id", scope: :private) do update end
          delete("/:id", scope: :private) do destroy end
        end
      end
    end

    # Rails style methods for easy overriding
    def index
      respond_with(collection, type: name, version: :v2)
    end

    def show
      respond_with(record, type: singular_name, version: :v2)
    end

    def update
      record.update(JSON.parse(request.body.read)[singular_name])
      if record.valid?
        repo_settings.save
        respond_with(record, type: singular_name, version: :v2)
      else
        status 422
        respond_with(record, type: :validation_error, version: :v2)
      end
    end

    def create
      record = collection.create(JSON.parse(request.body.read)[singular_name])
      if record.valid?
        repo_settings.save
        respond_with(record, type: singular_name, version: :v2)
      else
        status 422
        respond_with(record, type: :validation_error, version: :v2)
      end
    end

    def destroy
      record = collection.destroy(params[:id]) || record_not_found
      repo_settings.save
      respond_with(record, type: singular_name, version: :v2)
    end

    def singular_name
      name.to_s.singularize
    end

    def collection
      @collection ||= repo_settings.send(name)
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
  end
end
