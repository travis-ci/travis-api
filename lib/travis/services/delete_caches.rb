require 'travis/services/base'

module Travis
  module Services
    class DeleteCaches < Base
      register :delete_caches

      def run
        raise Travis::AuthorizationDenied unless authorized?

        caches = run_service(:find_caches, params)
        caches.each { |c| c.destroy }
        caches
      end

    private

      def authorized?
        current_user && repo && current_user.permission?(:push, repository_id: repo.id)
      end

      def repo
        @repo ||= run_service(:find_repo, params)
      end
    end
  end
end
