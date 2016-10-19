require 'travis/api'

module Services
  module Settings
    class Update
      include Travis::API
      attr_reader :repository_id, :setting, :value

      def initialize(repository_id, setting, value)
        @repository_id = repository_id
        @setting = setting
        @value = value
      end

      def call
        url = "/repo/#{repository_id}/setting/#{setting}"
        patch(url, param(value))
      end

      private

      def param(value)
        JSON.dump('setting.value' => value)
      end
    end
  end
end
