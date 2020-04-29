require 'travis/api/v3/renderer/owner'

module Travis::API::V3
  class Renderer::User < Renderer::Owner
    representation(:standard, :email, :is_syncing, :synced_at, :recently_signed_up, :secure_user_hash)
    representation(:additional, :emails)

    def email
      @model.email if current_user?
    end

    def emails
      current_user? ? @model.emails.map(&:email) : []
    end

    def secure_user_hash
      hmac_secret_key = Travis.config.intercom && Travis.config.intercom.hmac_secret_key.to_s
      OpenSSL::HMAC.hexdigest('sha256', hmac_secret_key, @model.id.to_s) if @model.id && hmac_secret_key
    end

    private

    def current_user?
      access_control.class == Travis::API::V3::AccessControl::LegacyToken && access_control.user.id == @model.id
    end
  end
end
