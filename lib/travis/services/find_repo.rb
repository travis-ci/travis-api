require 'travis/services/base'

module Travis
  module Services
    class FindRepo < Base
      register :find_repo

      scope_access!

      def run(options = {})
        result
      end

      def updated_at
        result.try(:updated_at)
      end

      private

        def result
          puts "Travis::Services::FindRepo params: #{params.inspect}"
          puts "Travis::Services::FindRepo result: #{@result.inspect}"
          puts "Travis::Services::FindRepo scope: #{scope(:repository).by_params(params).to_a.first}"
          @result ||= scope(:repository).by_params(params).to_a.first
        end
    end
  end
end
