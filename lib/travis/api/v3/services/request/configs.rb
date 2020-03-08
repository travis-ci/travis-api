module Travis::API::V3
  class Services::Request::Configs < Service
    result_type :request_configs
    params :ref, :config, :mode, :data

    def run
      repository = check_login_and_find(:repository)
      access_control.permissions(repository).create_request!
      user = access_control.user
      result query(:request_configs).expand(user, repo)
    end

    private

      def repo
        @repo ||= find(:repository)
      end
  end
end
