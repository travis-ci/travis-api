module Travis::API::V3
  class Models::Cron < Model

    belongs_to :branch

    LastBuild = -1
    ThisBuild = 0
    NextBuild = 1

    def next_enqueuing
      if disable_by_build && last_non_cron_build_date > planned_time(LastBuild)
        planned_time(NextBuild)
      elsif last_cron_build_date >= planned_time(LastBuild)
        planned_time(ThisBuild)
      else
        Time.now
      end
    end

    def planned_time(in_builds = ThisBuild)
      case interval
      when 'daily'
        planned_time_daily(in_builds)
      when 'weekly'
        planned_time_weekly(in_builds)
      when 'monthly'
        planned_time_monthly(in_builds)
      end
    end

    def planned_time_daily(in_builds)
      now = DateTime.now
      build_today = DateTime.new(now.year, now.month, now.day, created_at.hour)
      return build_today + 1 + in_builds if (now > build_today)
      build_today + in_builds
    end

    def planned_time_weekly(in_builds)
      now = DateTime.now
      build_today = DateTime.new(now.year, now.month, now.day, created_at.hour)
      next_time = build_today + ((created_at.wday - now.wday) % 7)
      return build_today + 7 * (1 + in_builds) if (now > next_time)
      next_time + 7 * in_builds
    end

    def planned_time_monthly(in_builds)
      now = DateTime.now
      created = DateTime.new(created_at.year, created_at.month, created_at.day, created_at.hour)
      month_since_creation = (now.year * 12 + now.month) - (created_at.year * 12 + created_at.month)
      this_month = created >> month_since_creation
      return created >> (month_since_creation + 1 + in_builds) if (now > this_month)
      created >> (month_since_creation + in_builds)
    end

    def last_cron_build_date
      last_cron_build = Models::Build.where(
          :repository_id => branch.repository.id,
          :branch => branch.name,
          :event_type => 'cron'
      ).order("id DESC").first
      return last_cron_build.created_at unless last_cron_build.nil?
      Time.at(0)
    end

    def last_non_cron_build_date
      last_build = Models::Build.where(
          :repository_id => branch.repository.id,
          :branch => branch.name
      ).where(['event_type NOT IN (?)', ['cron']]).order("id DESC").first
      return last_build.created_at unless last_build.nil?
      Time.at(0)
    end

  end
end
