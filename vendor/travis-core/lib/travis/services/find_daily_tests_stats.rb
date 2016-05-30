require 'travis/services/base'

module Travis
  module Services
    class FindDailyTestsStats < Base
      register :find_daily_tests_stats

      def run
        select scope(:job).
          select(['date(created_at) AS date', 'count(created_at) AS count']).
          group('date').
          order('date').
          where(['created_at > ?', 28.days.ago]).to_sql
      end

      private

        def select(sql)
          ActiveRecord::Base.connection.select_all(sql)
        end
    end
  end
end
