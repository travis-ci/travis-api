require 'travis/api'

module Services
  module Job
    class GetLog
      include Travis::API
      attr_reader :job

      def initialize(job)
        @job = job
      end

      def call
        url = "/job/#{job.id}/log"
        get(url, access_token)
      end

      private

      def access_token
        raise "Error: No Admin for this repository. See issue https://github.com/travis-pro/team-teal/issues/1436." unless admin
        Travis::AccessToken.create(user: admin, app_id: 2).token if admin
      end

      def admin
        job.repository.find_admin
      end
    end
  end
end
