module Travis::API::V3
  class Models::Cron < Model

    belongs_to :branch

    def next_enqueuing

      if (disable_by_build) && (last_non_cron_build_date > plannedTime(-1))
        return plannedTime(1)
      elsif last_cron_build_date >= plannedTime(-1)
        return plannedTime(0)
      else
        return Time.now
      end
    end

    def plannedTime(in_builds = 0) # 0 equals next build, 1 after next build, -1 last build, ...
      now = DateTime.now
      created = DateTime.new(created_at.year, created_at.month, created_at.day, created_at.hour)
      case interval
      when 'daily'
        build_today = DateTime.new(now.year, now.month, now.day, created_at.hour)
        if now > build_today
          return build_today + 1 + in_builds
        else
          return build_today + in_builds
        end
      when 'weekly'
        build_today = DateTime.new(now.year, now.month, now.day, created_at.hour)
        in_days = (created_at.wday - now.wday) % 7
        next_time = build_today + in_days
        if now > next_time
          return build_today + 7 * (1 + in_builds)
        else
          return next_time + 7 * in_builds
        end
      when 'monthly'
        month_since_creation = (now.year*12+now.month) - (created_at.year*12+created_at.month)
        this_month = created >> month_since_creation
        if now > this_month
          return created >> (month_since_creation + 1 + in_builds)
        else
          return created >> (month_since_creation + in_builds)
        end
      end
    end

    def last_cron_build_date
      last_cron_build = Models::Build.where(:repository_id => branch.repository.id, :branch => branch.name, :event_type => 'cron').order("id DESC").first
      return last_cron_build.created_at unless last_cron_build.nil?
      return Time.at(0)
    end

    def last_non_cron_build_date
      last_build = Models::Build.where(:repository_id => branch.repository.id, :branch => branch.name).where(['event_type NOT IN (?)', ['cron']]).order("id DESC").first
      return last_build.created_at unless last_build.nil?
      return Time.at(0)
    end

  end
end
