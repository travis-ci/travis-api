require 'travis/api/v3/renderer/owner'

module Travis::API::V3
  class Renderer::User < Renderer::Owner
    representation(:standard, :is_syncing, :synced_at)
    representation(:additional, :developer_program)

    def developer_program
      return true if Travis::Features.owner_active?(:developer_program, @model)
      @model.organizations.any? { |o| Travis::Features.owner_active?(:developer_program, o) }
    end
  end
end
