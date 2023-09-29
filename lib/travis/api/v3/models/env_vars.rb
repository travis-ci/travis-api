require_relative './json_sync'

module Travis::API::V3
  class Models::EnvVars < Travis::Settings::Collection
    include Models::JsonSync
    include ActiveSupport::Callbacks
    extend ActiveSupport::Concern

    model Models::EnvVar

    define_callbacks :after_save
    set_callback :after_save, :after, :save_audit

    attr_accessor :user, :change_source

    # See Models::JsonSync
    def to_h
      { 'env_vars' => map(&:to_h).map(&:stringify_keys) }
    end

    def create(attributes)
      @changes = { env_vars: { created: "#{attributes.except("value")}" } }
      env_var = super(attributes).tap { sync! }
      run_callbacks :after_save
      env_var
    end

    def add(env_var)
      destroy(env_var.id) if find(env_var.id)
      create(env_var.attributes)
    end

    def destroy(id)
      env_var = find(id)
      @changes = { env_vars: { deleted: "#{env_var.attributes.delete("value")}" } }
      deleted_env_var = super(id).tap { sync! }
      run_callbacks :after_save
      deleted_env_var
    end

    def repository
      @repository ||= Models::Repository.find(additional_attributes[:repository_id])
    end

    def changes
      @changes
    end

    private

    def save_audit
      if self.change_source
        Travis::API::V3::Models::Audit.create!(
          owner: self.user,
          change_source: self.change_source,
          source: self.repository,
          source_changes: {
            settings: self.changes
          }
        )
        @changes = {}
      end
    end
  end
end
