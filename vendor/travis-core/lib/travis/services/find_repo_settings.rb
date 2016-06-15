require 'travis/services/base'

module Travis
  module Services
    class FindRepoSettings < Base
      register :find_repo_settings

      def run(options = {})
        result if repo && authorized?
      end

      def updated_at
        result.try(:updated_at)
      end

      def authorized?
        current_user && current_user.permission?(:push, :repository_id => repo.id)
      end

      private

        def repo
          @repo ||= run_service(:find_repo, params)
        end

        def result
          repo.settings if repo
        end
    end
  end
end
