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
          repositories = current_user.try(:repositories)  || scope(:repository)
          @result ||= repositories.find_by(params)
        end

        def has_current_user?
          !current_user.nil?
        end
    end
  end
end
