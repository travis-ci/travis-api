require 'travis/api/v3/renderer/avatar_url'

module Travis::API::V3
  class Renderer::Owner < ModelRenderer
    include Renderer::AvatarURL

    representation(:minimal,    :id, :login, :vcs_type)
    representation(:standard,   :id, :login, :name, :github_id, :vcs_id, :vcs_type, :avatar_url, :education,
                   :allow_migration, :allowance)
    representation(:additional, :repositories, :installation)

    def initialize(*)
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
      return BillingClient.default_allowance_response if Travis.config.org?
      return BillingClient.default_allowance_response unless access_control.user

      client = BillingClient.new(access_control.user.id)
      client.allowance(owner_type, id)
    end

    def owner_type
      vcs_type.match(/User$/) ? 'User' : 'Organization'
    end
  end
end
