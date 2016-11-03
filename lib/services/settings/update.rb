require 'travis/api'

module Services
  module Settings
    class Update
      include Travis::API
      attr_reader :repository, :setting, :value

      def initialize(repository, setting, value)
        @repository = repository
        @setting = setting
        @value = value
      end

      def access_token
        admin = repository.find_admin
        Travis::AccessToken.create(user: admin, app_id: 2).token if admin
      end

      def call
        url = "/repo/#{repository.id}/setting/#{setting}"
        patch(url, access_token, param(value))
      end

      private

      def param(value)
        JSON.dump('setting.value' => value)
      end
    end
  end
end
