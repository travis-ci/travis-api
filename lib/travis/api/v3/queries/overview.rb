module Travis::API::V3
  class Queries::Overview < Query

    def build_duration(repo)
      Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name).where("duration IS NOT NULL").where("state != 'canceled'").order("id DESC").first(20)
    end

    def event_type(repo)
      Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name).group(:event_type, :state).count
    end

    def recent_build_history(repo)
      Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name).where("created_at > ?", Date.today - 9).group("date_trunc('day', created_at)", :state).count
    end

    def streak(repo)
      subquery = Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => ['failed', 'canceled', 'errored'], :event_type => ['push', 'cron']).order("id DESC").select(:id).limit(1)
      subquery = "SELECT COALESCE((" + subquery.to_sql + "), 0)"
      Models::Build.select('COUNT(*) AS "count", MIN(created_at) AS "created_at", "event_type"').where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'passed', :event_type => ['push', 'cron']).where("id > (#{subquery})").group(:event_type).to_a
    end

    def branches(repo)
      Models::Build.select('COUNT(*) AS "count", "branch", "state"').where(:repository_id => repo.id, :event_type => ['push', 'cron']).where("created_at > ?", Date.today - 30).group(:branch, :state).to_a
    end
  end
end
