require 'metriks'
require 'travis/mailer/user_mailer'
require 'travis/services/base'

module Travis
  module Github
    module Services
      class SyncUser < Travis::Services::Base
        require 'travis/github/services/sync_user/organizations'
        require 'travis/github/services/sync_user/repositories'
        require 'travis/github/services/sync_user/repository'
        require 'travis/github/services/sync_user/reset_token'
        require 'travis/github/services/sync_user/user_info'

        register :github_sync_user

        def run
          new_user? do
            syncing do
              # if Time.now.utc.tuesday? && Travis::Features.feature_active?("reset_token_in_sync")
              #   ResetToken.new(user).run
              # end
              UserInfo.new(user).run
              Organizations.new(user).run
              Repositories.new(user).run
            end
          end
        ensure
          user.update_column(:is_syncing, false)
        end

        def user
          # TODO check that clients are only passing the id
          @user ||= current_user || User.find(params[:id])
        end

        def new_user?
          new_user = user.synced_at.nil? && user.created_at > 48.hours.ago.utc

          yield if block_given?

          if new_user and Travis.config.welcome_email
            send_welcome_email
          end
        end

        def send_welcome_email
          return unless user.email.present?
          UserMailer.welcome_email(user).deliver
          logger.info("Sent welcome email to #{user.login}")
          Metriks.meter('travis.welcome.email').mark
        end

        private

          def syncing
            unless user.github_oauth_token?
              logger.warn "user sync for #{user.login} (id:#{user.id}) was cancelled as the user doesn't have a token"
              return
            end
            user.update_column(:is_syncing, true)
            result = yield
            user.update_column(:synced_at, Time.now)
            result
          rescue GH::TokenInvalid => e
            logger.warn "user sync for #{user.login} (id:#{user.id}) failed as the token was invalid, dropping the token"
            user.update_column(:github_oauth_token, nil)
          ensure
            user.update_column(:is_syncing, false)
          end
      end
    end
  end
end
