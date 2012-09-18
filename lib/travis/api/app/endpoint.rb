require 'travis/api/app'

class Travis::Api::App
  # Superclass for HTTP endpoints. Takes care of prefixing.
  class Endpoint < Responder
    set(:prefix) { "/" << name[/[^:]+$/].underscore }
    set disable_root_endpoint: false
    register :scoping

    before { content_type :json }
    error(ActiveRecord::RecordNotFound, Sinatra::NotFound) { not_found }
    not_found { content_type =~ /json/ ? { 'file' => 'not found' } : 'file not found' }

    private

      def service(key, user = current_user)
        const = Travis.services[key] || raise("no service registered for #{key}")
        const.new(user)
      end

      def current_user
        env['travis.access_token'].user if env['travis.access_token']
      end

      def redis
        Thread.current[:redis] ||= ::Redis.connect(url: Travis.config.redis.url)
      end
  end
end
