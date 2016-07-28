require 'travis/api'

module Services
  module Build
    class Restart
      include Travis::API
      attr_reader :build_id

      def initialize(build_id)
        @build_id = build_id
      end

      def call
        url = "/build/#{@build_id}/restart"
        post(url)
      end
    end
  end
end