module Services
  module Job
    class GenerateLogUrl
      attr_reader :job

      def initialize(job)
        @job = job
      end

      def call
        "#{api_endpoint}/jobs/#{job.id}/log.txt?deansi=true&access_token=#{access_token}"
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
    end
  end
end
