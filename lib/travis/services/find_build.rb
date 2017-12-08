require 'travis/services/base'

module Travis
  module Services
    class FindBuild < Base
      register :find_build

      def run
        result
      end

      def final?
        # TODO builds can be requeued, so finished builds are no more final
        # result.try(:finished?)
        false
      end

      def updated_at
        max = all_resources.max_by(&:updated_at)
        max.updated_at if max.respond_to?(:updated_at)
      end

      private

        def all_resources
          if result
            all = [result, result.commit, result.request, result.matrix.to_a]
            all.flatten.find_all { |r| r.updated_at }
          else
            []
          end
        end

        def result
          @result ||= load_result
        end

        def load_result
          columns = scope(:build).column_names
          columns -= %w(config) if params[:exclude_config]
          columns = columns.map { |c| %Q{"builds"."#{c}"} }
          scope(:build).includes([:matrix, :commit, :request]).select(columns).find_by_id(params[:id]).tap do |res|
            res.config = {} if params[:exclude_config]
          end
        end
    end
  end
end
