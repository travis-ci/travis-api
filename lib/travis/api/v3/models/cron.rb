module Travis::API::V3
  class Models::Cron < Model

    belongs_to :branch

    def self.start_all
      started = []

      self.all.each do |cron|
        if cron.next_build_time <= Time.now
          cron.start
          started.push cron
        end
      end

      started
    end

    def start
      raise ServerError, 'repository does not have a github_id'.freeze unless branch.repository.github_id

      payload = {
        repository: { id: branch.repository.github_id, owner_name: branch.repository.owner_name, name: branch.repository.name },
        branch:     branch.name
      }

      class_name, queue = Query.sidekiq_queue(:build_request)
      ::Sidekiq::Client.push('queue'.freeze => queue, 'class'.freeze => class_name, 'args'.freeze => [{type: 'cron'.freeze, payload: JSON.dump(payload)}])
      payload
    end

    def next_build_time

      if (disable_by_build) && (last_non_cron_build_date > last_planned_time)
        return after_next_planned_time
      elsif last_cron_build_date >= last_planned_time
        return next_planned_time
      else
        return Time.now
      end
    end

    def next_planned_time
      now = DateTime.now
      created = DateTime.new(created_at.year, created_at.month, created_at.day, created_at.hour)
      case interval
      when 'daily'
        build_today = DateTime.new(now.year, now.month, now.day, created_at.hour)
        if now > build_today
          return build_today + 1
        else
          return build_today
        end
      when 'weekly'
        build_today = DateTime.new(now.year, now.month, now.day, created_at.hour)
        in_days = (created_at.wday - now.wday) % 7
        next_time = build_today + in_days
        if now > next_time
          return build_today + 7
        else
          return next_time
        end
      when 'monthly'
        month_since_creation = (now.year*12+now.month) - (created_at.year*12+created_at.month)
        this_month = created >> month_since_creation
        if now > this_month
          return created >> (month_since_creation+1)
        else
          return this_month
        end
      end
    end

    def last_planned_time
      now = DateTime.now
      created = DateTime.new(created_at.year, created_at.month, created_at.day, created_at.hour)
      case interval
      when 'daily'
        return next_planned_time - 1
      when 'weekly'
        return next_planned_time - 7
      when 'monthly'
        month_since_creation = (now.year*12+now.month) - (created_at.year*12+created_at.month)
        this_month = created >> month_since_creation
        if now > this_month
          return this_month
        else
          return created >> (month_since_creation-1)
        end
      end
    end

    def after_next_planned_time
      now = DateTime.now
      created = DateTime.new(created_at.year, created_at.month, created_at.day, created_at.hour)
      case interval
      when 'daily'
        return next_planned_time + 1
      when 'weekly'
        return next_planned_time + 7
      when 'monthly'
        month_since_creation = (now.year*12+now.month) - (created_at.year*12+created_at.month)
        this_month = created >> month_since_creation
        if now > this_month
          return created >> (month_since_creation+2)
        else
          return created >> (month_since_creation+1)
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
