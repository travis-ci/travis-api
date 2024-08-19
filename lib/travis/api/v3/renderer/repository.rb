module Travis::API::V3
  class Renderer::Repository < ModelRenderer
    representation(:minimal,  :id, :name, :slug)
    representation(:standard, :id, :name, :slug, :description, :github_id, :vcs_id, :vcs_type, :github_language, :active, :private, :owner, :owner_name, :vcs_name, :default_branch, :starred, :managed_by_installation, :active_on_org, :migration_status, :history_migration_status, :shared, :config_validation, :server_type, :scan_failed_at)
    representation(:experimental, :id, :name, :slug, :description, :vcs_id, :vcs_type, :github_id, :github_language, :active, :private, :owner, :default_branch, :starred, :current_build, :last_started_build, :next_build_number, :server_type, :scan_failed_at)
    representation(:internal, :id, :name, :slug, :github_id, :vcs_id, :vcs_type, :active, :private, :owner, :default_branch, :private_key, :token, :user_settings, :server_type, :scan_failed_at)
    representation(:list, :id, :name, :slug, :active, :private, :owner, :vcs_id, :vcs_type, :server_type)
    representation(:minimal_with_build, :id, :name, :slug, :active, :private, :owner, :vcs_id, :vcs_type, :server_type, :managed_by_installation, :last_started_build, :current_build)
    representation(:additional, :allow_migration)

    hidden_representations(:experimental, :internal)

    def self.available_attributes
      super.add('email_subscribed')
    end

    def representation
      representation = params['representation'] if access_control.full_access?
      representation&.to_sym || super
    end

    def active
      !!model.active
    end

    def allow_migration
      model.allow_migration?
    end

    def default_branch
      return model.default_branch if include_default_branch?
      {
        :@type           => 'branch'.freeze,
        :@href           =>  Renderer.href(:branch, name: model.default_branch_name, repository_id: id, script_name: script_name),
        :@representation => 'minimal'.freeze,
        :name            => model.default_branch_name
      }
    end

    def current_build
      build = model.current_build
      build if access_control.visible? build
    end

    def last_started_build
      build = model.last_started_build
      build if access_control.visible? build
    end

    def starred
      return false unless user = access_control.user
      user.starred_repository_ids.include? id
    end

    def shared
      return owner_name.downcase != access_control.user.login.downcase \
      && access_control.user.shared_repositories_ids.include?(id) if access_control.user && owner_name
      false
    end

    def email_subscribed
      return false unless user = access_control.user
      !user.email_unsubscribed_repository_ids.include?(id)
    end

    def include_default_branch?
      return true if include? 'repository.default_branch'.freeze
      return true if include.any? { |i| i.start_with? 'branch'.freeze }
      return true if included.any? { |i| i.is_a? Models::Branch and i.repository_id == id and i.name == model.default_branch_name }
    end

    def owner
      return nil         if model.owner_type.nil?
      return model.owner if include_owner?
      owner_href = Renderer.href(owner_type.to_sym, id: model.owner_id, script_name: script_name)

      if included_owner? and owner_href
        { :@href => owner_href }
      else
        result = { :@type => owner_type, :id => model.owner_id, :login => model.owner_name, :ro_mode => owner_ro_mode }
        result[:@href] = owner_href if owner_href
        result
      end
    end

    def owner_ro_mode
      return false unless Travis.config.org? && Travis.config.read_only?

      !Travis::Features.owner_active?(:read_only_disabled, model.owner)
    end

    def include_owner?
      return false if model.owner_type.nil?
      return false if included_owner?
      return true  if include? 'repository.owner'.freeze
      return true  if include.any? { |i| i.start_with? owner_type or i.start_with? 'owner'.freeze }
    end

    def included_owner?
      included.any? { |i| i.is_a? Model and i.class.polymorphic_name == model.owner_type and i.id == model.owner_id }
    end

    def owner_type
      @owner_type ||= model.owner_type.downcase if model.owner_type
    end

    def managed_by_installation
      model.managed_by_installation?
    end

    def server_type
      model.server_type || 'git'
    end
  end
end
