require 'travis/services/base'

module Travis
  module Services
    class RegenerateRepoKey < Base
      register :regenerate_repo_key

      def run(options = {})
        if repo && accept?
          regenerate
          repo.key
        end
      end

      def accept?
        has_permission?
      end

      private

        def regenerate
          repo.regenerate_key!
        end

        def repo
          @repo ||= service(:find_repo, params).run
        end

        def has_permission?
          current_user && current_user.permission?(:admin, :repository_id => repo.id)
        end

    end
  end
end
