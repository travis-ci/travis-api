require 'faraday'

module Services
  module Repository
    class Enable
      attr_reader :repository_id

      def initialize(repository_id)
        @repository_id = repository_id
      end

      def call
        url = "/repo/#{@repository_id}/enable"
        Services::CallTravisApi.new(url).post
      end
    end
  end
end
