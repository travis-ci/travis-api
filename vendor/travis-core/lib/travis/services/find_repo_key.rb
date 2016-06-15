require 'travis/services/base'

module Travis
  module Services
    class FindRepoKey < FindRepo
      register :find_repo_key

      def run(options = {})
        result
      end

      def updated_at
        result.try(:updated_at)
      end

      private

        def result
          @result ||= (repo = super) ? repo.key : nil
        end
    end
  end
end
