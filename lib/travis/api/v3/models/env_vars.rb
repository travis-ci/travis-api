require_relative './json_sync'

module Travis::API::V3
  class Models::EnvVars < Travis::Settings::Collection
    include Models::JsonSync
    model Models::EnvVar

    # See Models::JsonSync
    def to_h
      { 'env_vars' => map(&:to_h).map(&:stringify_keys) }
    end

    def create(attributes)
      super(attributes).tap { sync! }
    end

    def add(env_var)
      destroy(env_var.id) if find(env_var.id)
      create(env_var.attributes)
    end

    def destroy(id)
      super(id).tap { sync! }
    end

    def repository
      @repository ||= Models::Repository.find(additional_attributes[:repository_id])
    end
  end
end
