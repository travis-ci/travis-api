require 'travis/api'

module Services
  module Job
    class Restart
      include Travis::API
      attr_reader :job

      def initialize(job)
        @job = job
      end

      def access_token
        admin = job.repository.find_admin
        Travis::AccessToken.create(user: admin, app_id: 2).token if admin
      end

      def call
        url = "/job/#{job.id}/restart"
        post(url, access_token)
      end
    end
  end
end
