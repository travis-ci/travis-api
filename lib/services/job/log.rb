module Services
  module Job
    class Log
      attr_reader :job_id, :user

      def initialize(job_id, user)
        @job_id = job_id
        @user = user
      end

      def call
        @log = api.job(job_id).log.body
      rescue Travis::Client::NotLoggedIn => e
        puts e.message
      end

      private

      def api_endpoint
        Travis::Config.load.api_endpoint
      end

      def api
        @api ||= begin
          options = { 'uri' => api_endpoint }
          options['access_token'] = access_token.to_s if user
          Travis::Client.new(options)
        end
      end

      def access_token
        Travis::AccessToken.create(user: user, app_id: 2) if user
      end
    end
  end
end
