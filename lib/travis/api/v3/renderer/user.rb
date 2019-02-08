require 'travis/api/v3/renderer/owner'

module Travis::API::V3
  class Renderer::User < Renderer::Owner
    representation(:standard, :is_syncing, :synced_at, :first_logged_in_at)
    representation(:additional, :emails)

    def emails
      @model.emails.map(&:email)
    end

    def render(representation)
      result = super

      if hmac_secret_key
        result['secure_user_hash'] = secure_user_hash
      end

      result
    end

    private def hmac_secret_key
      Travis.config.intercom && Travis.config.intercom.hmac_secret_key
    end

    private def secure_user_hash
      OpenSSL::HMAC.hexdigest(
        'sha256',
        hmac_secret_key,
        "#{id}"
      )
    end
  end
end
