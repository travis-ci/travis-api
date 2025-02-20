require 'travis/api/v3/renderer/owner'

module Travis::API::V3
  class Renderer::User < Renderer::Owner
    representation(:standard, :email, :is_syncing, :synced_at, :recently_signed_up, :secure_user_hash, :ro_mode, :confirmed_at, :custom_keys, :internal)
    representation(:additional, :emails, :collaborator)

    def email
      @model.email if show_emails?
    end

    def emails
      show_emails? ? @model.emails.map(&:email) : []
    end

    def collaborator
      query(:user).collaborator? @model.id
    end

    def internal
      @model.internal?
    end

    def secure_user_hash
      hmac_secret_key = Travis.config.intercom && Travis.config.intercom.hmac_secret_key.to_s
      OpenSSL::HMAC.hexdigest('sha256', hmac_secret_key, @model.id.to_s) if @model.id && hmac_secret_key
    end

    def confirmed_at
      return Date.new(2000,1,1) if !!Travis.config.enterprise

      @model.confirmed_at
    end

    def ro_mode
      return false unless Travis.config.org? && Travis.config.read_only?

      current_user? ? !Travis::Features.owner_active?(:read_only_disabled, @model) : false
    end

    private

    def show_emails?
      current_user? || options[:show_email] == true
    end

    def current_user?
      access_control.class == Travis::API::V3::AccessControl::LegacyToken && access_control.user.id == @model.id
    end
  end
end
