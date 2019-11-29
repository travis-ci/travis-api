require 'travis/api/v3/renderer/owner'

module Travis::API::V3
  class Renderer::User < Renderer::Owner
    representation(:standard, :is_syncing, :synced_at, :recently_signed_up)
    representation(:additional, :emails)

    def emails
      require 'pry'; binding.pry
      @model.emails.map(&:email) if access_control.class == Travis::API::V3::AccessControl::LegacyToken && access_control.user.id == @model.id
      []
    end
  end
end
