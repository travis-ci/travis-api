require 'travis/a_p_i'

module Services
  module Repository
    class Disable
      include Travis::API
      attr_reader :repository_id

      def initialize(repository_id)
        @repository_id = repository_id
      end

      def call
        url = "/repo/#{@repository_id}/disable"
        post(url)
      end
    end
  end
end
