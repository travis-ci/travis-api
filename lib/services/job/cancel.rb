require 'travis/api'

module Services
  module Job
    class Cancel
      include Travis::API
      attr_reader :job_id

      def initialize(job_id)
        @job_id = job_id
      end

      def call
        url = "/job/#{@job_id}/cancel"
        post(url)
      end
    end
  end
end