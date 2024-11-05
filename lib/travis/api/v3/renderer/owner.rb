require 'travis/api/v3/renderer/avatar_url'

module Travis::API::V3
  class Renderer::Owner < ModelRenderer
    include Renderer::AvatarURL

    representation(:minimal,    :id, :login, :name, :vcs_type, :ro_mode)
    representation(:standard,   :id, :login, :name, :github_id, :vcs_id, :vcs_type, :avatar_url, :education,
                   :allow_migration, :allowance, :ro_mode, :custom_keys, :trial_allowed)
    representation(:additional, :repositories, :installation, :trial_allowed)

    def initialize(model, **options)
      super

      owner_includes = include.select { |i| i.start_with?('owner.'.freeze) }
      owner_includes.each { |i| include << i.sub('owner.'.freeze, "#{self.class.type}.") }
    end

    def repositories
      repositories = query(:repositories).for_owner(@model)
      access_control.visible_repositories(repositories)
    end

    def installation
      installation = model.installation
      installation if installation and access_control.visible? installation
    end

    def allow_migration
      !!Travis::Features.owner_active?(:allow_migration, @model)
    end

    def allowance
      return BillingClient.minimal_allowance_response(id) if !!Travis.config.enterprise

      return BillingClient.default_allowance_response(id) if Travis.config.org?
      return BillingClient.default_allowance_response(id) unless access_control.user

      BillingClient.minimal_allowance_response(id)
    end

    def trial_allowed
      query(:owner).trial_allowed(access_control&.user&.id, @model.id, @model.class.name.split('::').last)
    end

    def owner_type
      vcs_type.match(/User$/) ? 'User' : 'Organization'
    end

    def ro_mode
      return false unless Travis.config.org? && Travis.config.read_only?

      !Travis::Features.owner_active?(:read_only_disabled, model)
    end
  end
end
