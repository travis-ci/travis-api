require 'travis/api'

module Services
  module Job
    class Cancel
      include Travis::API
      attr_reader :job_id

      def initialize(job_id)
        @job_id = job_id
      end

      def access_token
        ENV['TRAVIS_API_TOKEN']
      end

      def call
        url = "/job/#{job_id}/cancel"
        post(url, access_token)
      end
    end
  end
end
