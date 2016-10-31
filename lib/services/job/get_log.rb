module Services
  module Job
    class GetLog
      attr_reader :job

      def initialize(job)
        @job = job
      end

      def call
        @log = api.job(job.id).log.body
      rescue Travis::Client::NotLoggedIn => e
        puts "Getting job log failed: #{e.message}"
      end

      private

      def access_token
        Travis::AccessToken.create(user: admin, app_id: 2) if admin
      end

      def admin
        job.repository.find_admin
      end

      def api_endpoint
        Travis::Config.load.api_endpoint
      end

      def api
        @api ||= begin
          options = { 'uri' => api_endpoint }
          options['access_token'] = access_token.to_s if admin
          Travis::Client.new(options)
        end
      end
    end
  end
end
