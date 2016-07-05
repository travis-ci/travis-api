require 'travis/services/base'

module Travis
  module Services
    class DeleteCaches < Base
      register :delete_caches

      def run
        caches = run_service(:find_caches, params)
        caches.each { |c| c.destroy }
        caches
      end
    end
  end
end
