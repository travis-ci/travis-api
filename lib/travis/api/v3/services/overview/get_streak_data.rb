module Travis::API::V3
  class Services::Overview::GetStreakData < Service

    DataContainer = Struct.new :streak

    def run!
      repo = find(:repository)
      last_failing_build = Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'failed').order("id DESC").first
      first_build_of_streak = Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'passed').where("id > ?", last_failing_build.id).order("id ASC").first

      build_count = Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'passed').where("id > ?", last_failing_build.id).count
      day_count = 0

      if build_count > 0
        day_count = ((Time.now - first_build_of_streak.finished_at)/(60*60*24)).floor
      end

      [{
        days: day_count,
        builds: build_count
      }]
    end
  end
end
