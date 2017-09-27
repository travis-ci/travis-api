module Services
  module Job
    class GetLog
      attr_reader :job

      def initialize(job)
        @job = job
      end

      def call
        @log = api.get_raw("/jobs/#{job.id}/log", nil, 'Accept' => '*/*')
      rescue Travis::Client::NotLoggedIn => e
        puts "Getting job log failed: #{e.message}"
      end

      private

      def access_token
        raise "Error: No Admin for this repository. See issue https://github.com/travis-pro/team-teal/issues/1436." unless admin
        Travis::AccessToken.create(user: admin, app_id: 2)
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
