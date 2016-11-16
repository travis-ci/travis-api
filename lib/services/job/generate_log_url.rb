module Services
  module Job
    class GenerateLogUrl
      attr_reader :job

      def initialize(job)
        @job = job
      end

      def call
        "#{api_endpoint}/jobs/#{job.id}/logs.txt?deansi=true&access_token=#{access_token}"
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
    end
  end
end