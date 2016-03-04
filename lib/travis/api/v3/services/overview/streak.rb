module Travis::API::V3
  class Services::Overview::Streak < Service

    def run!
      result = query.streak(find(:repository))

      start_of_streak = DateTime::Infinity.new
      build_count = 0

      for builds in result
        if builds.created_at < start_of_streak
          start_of_streak = builds.created_at
        end
        if builds.event_type == "push"
          build_count = builds.count.to_i
        end
      end

      day_count = (build_count > 0) ? ((Time.now - start_of_streak)/(60*60*24)).floor : 0

      [{streak: {days: day_count, builds: build_count}}]
    end
  end
end
