require 'addressable/uri'
require 'active_record/base'
require 'travis/api/app'
require 'travis/api/app/base'

class Travis::Api::App
  # Superclass for HTTP endpoints. Takes care of prefixing.
  class Endpoint < Base
    include Travis::Services::Helpers

    set(:prefix) { "/" << name[/[^:]+$/].underscore }
    set disable_root_endpoint: false
    register :scoping
    helpers :current_user, :flash, :db_follower
    set :check_auth, true

    # TODO hmmm?
    before { flash.clear }
    after { content_type :json unless content_type }

    before do
      halt 406 if accept_version == 'v2.1' && ENV['DISABLE_V2_1']
      if settings.check_auth?
        halt 403 if force_auth? && !authenticated?
      end
    end

    error(ActiveRecord::RecordNotFound, Sinatra::NotFound) { not_found }
    not_found {
      if content_type =~ /json/
        if body && !body.empty?
          body
        else
          { 'file' => 'not found' }
        end
      else
        'file not found'
      end
    }

    error Travis::AuthorizationDenied do
      status 403
      {}
    end

    private

      def authenticate_by_mode!
        return if org? || authenticated?
        halt 401 if private_mode? || pre_v2_1?
      end

      MSGS = {
        migrated: 'This repository has been migrated to travis-ci.com. Modifications to this repository, it\'s builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com'
      }

      def disallow_migrating!(repo)
        if Travis.config.org? && (repo.migration_status == "migrating" || repo.migration_status == "migrated")
          # this shouldn't be really done like that but since
          # disallow_migrating! is implemented in a way it is, it's the simplest
          # thing to do and since we're not planning to work on API V2 too much,
          # I'll just leave it at that
          if acceptable_formats.any? { |f| f.accepts?("application/json") }
            halt 403, { error_type: "migrated_repository", error_message: MSGS[:migrated] }
          else
            halt 403, MSGS[:migrated]
          end
        end
      end

      def allow_public?
        org? || public_mode?
      end

      def authenticated?
        !!env['travis.access_token']
      end

      def public_mode?
        Travis.config[:public_mode]
      end

      def private_mode?
        !public_mode?
      end

      def org?
        Travis.config.org?
      end

      def com?
        !org?
      end

      def force_auth?
        Travis.config.force_authentication?
      end

      def pre_v2_1?
        accept_version.to_s < 'v2.1'
      end

      def redis
        Travis.redis
      end

      def endpoint(link, query_values = {})
        link = url(File.join(env['travis.global_prefix'], link), true, false)
        uri  = Addressable::URI.parse(link)
        query_values = query_values.merge(uri.query_values) if uri.query_values
        uri.query_values = query_values
        uri.to_s
      end

      def authorizer
        @_authorizer ||= Travis::API::V3::Authorizer::new(current_user&.id)
      end

      def auth_for_repo(id, type)
        permission = authorizer.for_repo(id, type)
        halt 403, { error: { message: "We're sorry, but you're not authorized to perform this request" } } unless permission
      rescue Travis::API::V3::AuthorizerError
      end
  end
end

require 'travis/api/app/endpoint/accounts'
require 'travis/api/app/endpoint/authorization'
require 'travis/api/app/endpoint/branches'
require 'travis/api/app/endpoint/broadcasts'
require 'travis/api/app/endpoint/builds'
require 'travis/api/app/endpoint/build_backups'
require 'travis/api/app/endpoint/documentation'
require 'travis/api/app/endpoint/endpoints'
require 'travis/api/app/endpoint/env_vars'
require 'travis/api/app/endpoint/error'
require 'travis/api/app/endpoint/home'
require 'travis/api/app/endpoint/hooks'
require 'travis/api/app/endpoint/jobs'
require 'travis/api/app/endpoint/lint'
require 'travis/api/app/endpoint/logout'
require 'travis/api/app/endpoint/logs'
require 'travis/api/app/endpoint/pusher'
require 'travis/api/app/endpoint/repos'
require 'travis/api/app/endpoint/requests'
require 'travis/api/app/endpoint/setting_endpoint'
require 'travis/api/app/endpoint/singleton_settings_endpoint'
require 'travis/api/app/endpoint/slow'
require 'travis/api/app/endpoint/uptime'
require 'travis/api/app/endpoint/users'
