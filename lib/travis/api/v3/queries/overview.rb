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
  end
end
