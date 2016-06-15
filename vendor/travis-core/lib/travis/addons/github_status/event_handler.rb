require 'travis/addons/github_status/instruments'
require 'travis/event/handler'

module Travis
  module Addons
    module GithubStatus

      # Adds a comment with a build notification to the pull-request the request
      # belongs to.
      class EventHandler < Event::Handler
        API_VERSION = 'v2'
        EVENTS = /build:(created|started|finished|canceled)/

        def handle?
          return token.present? unless multi_token?

          unless tokens.any?
            error "No GitHub OAuth tokens found for #{object.repository.slug}"
          end

          tokens.any?
        end

        def handle
          if multi_token?
            Travis::Addons::GithubStatus::Task.run(:github_status, payload, tokens: tokens)
          else
            Travis::Addons::GithubStatus::Task.run(:github_status, payload, token: token)
          end
        end

        private

        def token
          admin.try(:github_oauth_token)
        end

        def tokens
          @tokens ||= users.map { |user| { user.login => user.github_oauth_token } }.inject({}, :merge)
        end

        def users
          @users ||= [
            build_committer,
            admin,
            users_with_push_access,
          ].flatten.compact
        end

        def build_committer
          user = User.with_email(object.commit.committer_email)
          user if user && user.permission?(repository_id: object.repository.id, push: true)
        end

        def admin
          @admin ||= Travis.run_service(:find_admin, repository: object.repository)
        rescue Travis::AdminMissing
          nil
        end

        def users_with_push_access
          object.repository.users_with_permission(:push)
        end

        def multi_token?
          !Travis::Features.feature_deactivated?(:github_status_multi_tokens)
        end

        Instruments::EventHandler.attach_to(self)
      end
    end
  end
end

