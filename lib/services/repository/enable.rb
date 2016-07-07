require 'travis/a_p_i'

module Services
  module Repository
    class Enable
      include Travis::API
      attr_reader :repository_id

      def initialize(repository_id)
        @repository_id = repository_id
      end

      def call
        url = "/repo/#{@repository_id}/enable"
        post(url)
      end
    end
  end
end
