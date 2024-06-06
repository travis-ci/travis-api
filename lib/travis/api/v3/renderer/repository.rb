module Travis::API::V3
  class Renderer::Repository < ModelRenderer
    representation(:minimal,  :id, :name, :slug)
    representation(:standard, :id, :name, :slug, :description, :github_id, :vcs_id, :vcs_type, :github_language, :active, :private, :owner, :owner_name, :vcs_name, :default_branch, :starred, :managed_by_installation, :active_on_org, :migration_status, :history_migration_status, :shared, :config_validation, :server_type, :scan_failed_at)
    representation(:experimental, :id, :name, :slug, :description, :vcs_id, :vcs_type, :github_id, :github_language, :active, :private, :owner, :default_branch, :starred, :current_build, :last_started_build, :next_build_number, :server_type, :scan_failed_at)
    representation(:internal, :id, :name, :slug, :github_id, :vcs_id, :vcs_type, :active, :private, :owner, :default_branch, :private_key, :token, :user_settings, :server_type, :scan_failed_at)
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
      t1 = Time.now
      return model.default_branch if include_default_branch?
      {
        :@type           => 'branch'.freeze,
        :@href           =>  Renderer.href(:branch, name: model.default_branch_name, repository_id: id, script_name: script_name),
        :@representation => 'minimal'.freeze,
        :name            => model.default_branch_name
      }
    ensure
      puts "T:default_branch #{(Time.now - t1).in_milliseconds}"
    end

    def current_build
      t1 = Time.now
      build = model.current_build
      build if access_control.visible? build
    ensure
      puts "T:current_build #{(Time.now - t1).in_milliseconds}"
    end

    def last_started_build
      t1 = Time.now
      build = model.last_started_build
      build if access_control.visible? build
    ensure
      puts "T:last_started_build #{(Time.now - t1).in_milliseconds}"
    end

    def starred
      t1 = Time.now
      return false unless user = access_control.user
      user.starred_repository_ids.include? id

    ensure
      puts "T:starred #{(Time.now - t1).in_milliseconds}"
    end

    def shared
      t1 = Time.now
      return owner_name.downcase != access_control.user.login.downcase \
      && access_control.user.shared_repositories_ids.include?(id) if access_control.user && owner_name
      false

    ensure
      puts "T:shared #{(Time.now - t1).in_milliseconds}"
    end

    def email_subscribed
      t1 = Time.now
      return false unless user = access_control.user
      !user.email_unsubscribed_repository_ids.include?(id)
    ensure
      puts "T:email_subscribed #{(Time.now - t1).in_milliseconds}"
    end

    def include_default_branch?
      t1 = Time.now
      return true if include? 'repository.default_branch'.freeze
      return true if include.any? { |i| i.start_with? 'branch'.freeze }
      return true if included.any? { |i| i.is_a? Models::Branch and i.repository_id == id and i.name == model.default_branch_name }
    ensure
      puts "T:include_default_branch #{(Time.now - t1).in_milliseconds}"
    end

    def owner
      t1 = Time.now
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
    ensure
      puts "T:owner #{(Time.now - t1).in_milliseconds}"
    end

    def owner_ro_mode
      t1 = Time.now
      return false unless Travis.config.org? && Travis.config.read_only?

      !Travis::Features.owner_active?(:read_only_disabled, model.owner)
    ensure
      puts "T:owner_ro_mode #{(Time.now - t1).in_milliseconds}"
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
      t1 = Time.now
      model.managed_by_installation?
    ensure
      puts "T:managed_by_inst #{(Time.now - t1).in_milliseconds}"
    end

    def server_type
      t1 = Time.now
      model.server_type || 'git'
    ensure
      puts "T:server_type #{(Time.now - t1).in_milliseconds}"
    end
  end
end
