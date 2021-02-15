require 'travis/services/base'

module Travis
  module Services
    class FindBuildBackups < Base
      register :find_build_backups

      scope_access!

      def run
        result
      end

      private

      def result
        @result ||= scope(:build_backup).where(repository_id: params[:repository_id])
      end
    end
  end
end
