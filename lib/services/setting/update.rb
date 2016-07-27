require 'travis/api'

module Services
  module Setting
    class Update
      include Travis::API
      attr_reader :repository_id, :settings

      def initialize(repository_id, settings)
        @repository_id = repository_id
        @settings = settings
      end

      def call
        url = "/repo/#{@repository_id}/settings"
        patch(url, "settings", settings)
      end
    end
  end
end
