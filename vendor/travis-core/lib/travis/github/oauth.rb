module Travis
  module Github
    module Oauth
      class TrackScopes < Struct.new(:user)
        def run
          update if update?
        end

        private

          def update
            user.github_scopes = Oauth.scopes_for(user)
            user.save!
          end

          def update?
            github_oauth_token_changed?(user) or user.github_scopes.blank?
          end

          def github_oauth_token_changed?(user)
            user.github_oauth_token_changed? or user.previous_changes.key?('github_oauth_token')
          end
      end

      class << self
        def track_scopes(user)
          TrackScopes.new(user).run
        end

        def correct_scopes?(user)
          missing = wanted_scopes - user.github_scopes
          missing.empty?
        end

        def wanted_scopes
          Travis.config.oauth2.scope.to_s.split(',').sort
        end

        # TODO: Maybe this should move to gh?
        def scopes_for(token)
          token  = token.github_oauth_token if token.respond_to? :github_oauth_token
          scopes = GH.with(token: token.to_s) { GH.head('user') }.headers['x-oauth-scopes'] if token.present?
          scopes &&= scopes.gsub(/\s/,'').split(',')
          Array(scopes).sort
        rescue GH::Error
          []
        end
      end
    end
  end
end
