require 'travis/api'

module Services
  module Settings
    class Update
      include Travis::API
      attr_reader :repository_id, :settings

      def initialize(repository_id, settings)
        @repository_id = repository_id
        @settings = settings.map {|k, v| [k.dup.prepend("settings."), v]}.to_h
      end

      def call
        url = "/repo/#{@repository_id}/settings"
        patch(url, settings)
      end
    end
  end
end
