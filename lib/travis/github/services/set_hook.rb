require 'travis/github'
require 'travis/services/base'

module Travis
  module API; end # Load-order issue
  require 'travis/api/v3/github'

  module Github
    module Services
      class SetHook < Travis::Services::Base
        register :github_set_hook

        def run
          remote_vcs_repository.set_hook(
            repository_id: repo.id,
            user_id: current_user.id,
            activate: active?
          )
        end

        private

        def active?
          params[:active]
        end

        def v3_github
          @v3_github ||= Travis::API::V3::GitHub.new(current_user, current_user.github_oauth_token)
        end

        def repo
          @repo ||= run_service(:find_repo, id: params[:id])
        end
      end
    end
  end
end
