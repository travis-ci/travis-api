module Travis
  module Services
    class FindRequest < Base
      register :find_request

      def run(options = {})
        result
      end

      def final?
        true
      end

      def updated_at
        result.updated_at if result.respond_to?(:updated_at)
      end

      private

        def result
          @result ||= scope(:request).find_by_id(params[:id])
        end
    end
  end
end
