require 'travis/api'

module Services
  module Job
    class Cancel
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
        url = "/job/#{job.id}/cancel"
        post(url, access_token)
      end
    end
  end
end
