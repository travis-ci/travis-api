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

    # TODO hmmm?
    before { flash.clear }
    after { content_type :json unless content_type }

    error(ActiveRecord::RecordNotFound, Sinatra::NotFound) { not_found }
    not_found {
      if env['sinatra.route'] == 'GET /:owner_name/:name' && (env['travis.format'] == 'png' || env['travis.format'] == 'svg')
        root = File.expand_path('.')
        filename = "#{root}/public/images/result/unknown.#{env['travis.format']}"
        send_file(filename, type: :png)
      else
        if content_type =~ /json/
          if body && !body.empty?
            body
          else
            { 'file' => 'not found' }
          end
        else
          'file not found'
        end
      end
    }

    private

      def redis
        Thread.current[:redis] ||= ::Redis.connect(url: Travis.config.redis.url)
      end

      def endpoint(link, query_values = {})
        link = url(File.join(env['travis.global_prefix'], link), true, false)
        uri  = Addressable::URI.parse(link)
        query_values = query_values.merge(uri.query_values) if uri.query_values
        uri.query_values = query_values
        uri.to_s
      end

      def safe_redirect(url)
        redirect(endpoint('/redirect', to: url), 301)
      end
  end
end

require 'travis/api/app/endpoint/accounts'
require 'travis/api/app/endpoint/authorization'
require 'travis/api/app/endpoint/branches'
require 'travis/api/app/endpoint/broadcasts'
require 'travis/api/app/endpoint/builds'
require 'travis/api/app/endpoint/documentation'
require 'travis/api/app/endpoint/endpoints'
require 'travis/api/app/endpoint/env_vars'
require 'travis/api/app/endpoint/home'
require 'travis/api/app/endpoint/hooks'
require 'travis/api/app/endpoint/jobs'
require 'travis/api/app/endpoint/lint'
require 'travis/api/app/endpoint/logs'
require 'travis/api/app/endpoint/repos'
require 'travis/api/app/endpoint/requests'
require 'travis/api/app/endpoint/setting_endpoint'
require 'travis/api/app/endpoint/singleton_settings_endpoint'
require 'travis/api/app/endpoint/uptime'
require 'travis/api/app/endpoint/users'
