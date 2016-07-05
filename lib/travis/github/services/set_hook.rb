require 'travis/github'
require 'travis/services/base'

module Travis
  module Github
    module Services
      class SetHook < Travis::Services::Base
        EVENTS = [:push, :pull_request, :issue_comment, :public, :member]

        register :github_set_hook

        def run
          Github.authenticated(current_user) do
            update
          end
        end

        private

          def repo
            @repo ||= run_service(:find_repo, id: params[:id])
          end

          def active?
            params[:active]
          end

          def hook
            @hook ||= find || create
          end

          def update
            GH.patch(hook_url, payload) unless hook['active'] == active?
          end

          def find
            GH[hooks_url].detect { |hook| hook['name'] == 'travis' && hook['config']['domain'] == domain }
          end

          def create
            GH.post(hooks_url, payload)
          end

          def payload
            {
              :name   => 'travis',
              :events => EVENTS,
              :active => active?,
              :config => { :user => current_user.login, :token => current_user.tokens.first.token, :domain => domain }
            }
          end

          def hooks_url
            "repos/#{repo.slug}/hooks"
          end

          def hook_url
            hook['_links']['self']['href']
          end

          def domain
            Travis.config.service_hook_url || ''
          end
      end
    end
  end
end
