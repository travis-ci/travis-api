module Travis::API::V3
  class Services::Request::Configs < Service
    result_type :request_configs
    params :ref, :configs, :data
    params :config, :mode # BC

    def run
      repository = check_login_and_find(:repository)
      access_control.permissions(repository).create_request!
      user = access_control.user
      result query(:request_configs).expand(user, repo)
    end

    private

      def params
        @params = super.tap do |params|
          params['configs'] = [{ config: params['config'], mode: params['mode'] }] if params['config'] # BC
        end
      end

      def repo
        @repo ||= find(:repository)
      end
  end
end
