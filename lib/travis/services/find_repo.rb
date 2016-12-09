require 'travis/services/base'

module Travis
  module Services
    class FindRepo < Base
      register :find_repo

      def run(options = {})
        result
      end

      def updated_at
        result.try(:updated_at)
      end

      private

        def result
          @result ||= current_user.repositories.find_by(params)
        end
    end
  end
end
