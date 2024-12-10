module Travis::API
  module Sidekiq
    extend self

    def gatekeeper(*args)
      gatekeeper_client.push(
        'queue' => 'build_requests',
        'class' => 'Travis::Gatekeeper::Worker',
        'args' => args.map! { |a| a.to_json }
      )
    end

    private

      def client
        ::Sidekiq::Client
      end

      def gatekeeper_client
        if ENV['REDIS_GATEKEEPER_ENABLED'] != 'true'
          return client
        end

        @gatekeeper_client ||= ::Sidekiq::Client.new(gatekeeper_pool)
      end

      def gatekeeper_pool
        ::Sidekiq::RedisConnection.create(
          url: config.redis_gatekeeper.url,
          id: nil,
          ssl: config.redis_gatekeeper.ssl || false,
          ssl_params: redis_ssl_params
        )
      end

      def redis_ssl_params
        @redis_ssl_params ||= begin
            return {} unless Travis.config.redis_gatekeeper.ssl

            value = {}
            value[:ca_file] = ENV['REDIS_GATEKEEPER_SSL_CA_FILE'] if ENV['REDIS_GATEKEEPER_SSL_CA_FILE']
            value[:cert] = OpenSSL::X509::Certificate.new(File.read(ENV['REDIS_GATEKEEPER_SSL_CERT_FILE'])) if ENV['REDIS_GATEKEEPER_SSL_CERT_FILE']
            value[:key] = OpenSSL::PKEY::RSA.new(File.read(ENV['REDIS_GATEKEEPER_SSL_KEY_FILE'])) if ENV['REDIS_GATEKEEPER_SSL_KEY_FILE']
            value[:verify_mode] = OpenSSL::SSL::VERIFY_NONE if Travis.config.ssl_verify == false
            value
       end
      end

      def config
        Travis.config
      end
  end
end
