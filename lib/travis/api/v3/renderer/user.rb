require 'travis/api/v3/renderer/owner'

module Travis::API::V3
  class Renderer::User < Renderer::Owner
    representation(:standard, :is_syncing, :synced_at)
    representation(:additional, :emails)

    def emails
      @model.emails.map(&:email)
    end
  end
end
