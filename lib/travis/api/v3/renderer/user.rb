require 'travis/api/v3/renderer/owner'

module Travis::API::V3
  class Renderer::User < Renderer::Owner
    representation(:standard, :is_syncing, :synced_at, :recently_signed_up, :secure_user_hash)
    representation(:additional, :emails)

    def emails
      return @model.emails.map(&:email) if access_control.class == Travis::API::V3::AccessControl::LegacyToken && access_control.user.id == @model.id
      []
    end
    
    def secure_user_hash
      hmac_secret_key = Travis.config.intercom && Travis.config.intercom.hmac_secret_key
      OpenSSL::HMAC.hexdigest('sha256', hmac_secret_key, @model.id)
    end
  end
end
