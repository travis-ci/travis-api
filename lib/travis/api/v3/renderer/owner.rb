require 'travis/api/v3/renderer/avatar_url'

module Travis::API::V3
  class Renderer::Owner < ModelRenderer
    include Renderer::AvatarURL

    representation(:minimal,    :id, :login)
    representation(:standard,   :id, :login, :name, :github_id, :avatar_url)
    representation(:additional, :repositories)

    def initialize(*)
      super

      owner_includes = include.select { |i| i.start_with?('owner.'.freeze) }
      owner_includes.each { |i| include << i.sub('owner.'.freeze, "#{self.class.type}.") }
    end

    def repositories
      repositories = query(:repositories).for_owner(@model)
      access_control.visible_repositories(repositories)
    end
  end
end
