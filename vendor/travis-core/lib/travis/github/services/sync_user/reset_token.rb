require "gh"

module Travis
  module Github
    module Services
      class SyncUser < Travis::Services::Base
        class ResetToken
          def initialize(user, config = Travis.config.oauth2.to_h, gh = nil)
            @user = user
            @config = config
            @gh = gh || GH.with(username: @config.client_id, password: @config.client_secret)
          end

          def run
            token = new_token
            @user.update_attributes!(github_oauth_token: token) if token
          end

          private

          def new_token
            @new_token ||= @gh.post("/applications/#{client_id}/tokens/#{@user.github_oauth_token}", {})["token"]
          end

          def client_id
            @config.client_id
          end

          def client_secret
            @config.client_secret
          end
        end
      end
    end
  end
end
