module Travis::API::V3
  class Services::Overview::Streak < Service

    def run!
      repo = find(:repository)
      last_failing_build = Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => ['failed', 'canceled', 'errored'], :event_type => ['push', 'cron']).order("id DESC").first

      fail_id = (last_failing_build != nil) ? last_failing_build.id : 0

      first_build_of_streak = Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'passed', :event_type => ['push', 'cron']).where("id > ?", fail_id).order("id ASC").first
      build_count = Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'passed', :event_type => 'push').where("id > ?", fail_id).count

      day_count = (build_count > 0) ? ((Time.now - first_build_of_streak.created_at)/(60*60*24)).floor : 0

      [{streak: {days: day_count, builds: build_count}}]
    end
  end
end
