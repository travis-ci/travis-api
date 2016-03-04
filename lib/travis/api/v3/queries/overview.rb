module Travis::API::V3
  class Queries::Overview < Query

    def build_duration(repo)
      Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name).where("duration IS NOT NULL").where("state != 'canceled'").order("id DESC").select("id, number, state, duration").last(20)
    end

    def event_type(repo)
      Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name).group(:event_type, :state).count
    end

    def recent_build_history(repo)
      Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name).where("created_at > ?", Date.today - 9).group("date_trunc('day', created_at)", :state).count
    end

    def streak_last_failing_build_id(repo)
      last_failing_build = Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => ['failed', 'canceled', 'errored'], :event_type => ['push', 'cron']).order("id DESC").select(:id).first
      (last_failing_build != nil) ? last_failing_build.id : 0
    end

    def streak(repo)
      Models::Build.select('COUNT(*) AS "count", MIN(created_at) AS "created_at", "event_type"').where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'passed', :event_type => ['push', 'cron']).where("id > ?", streak_last_failing_build_id(repo)).group(:event_type).to_a
    end
  end
end
