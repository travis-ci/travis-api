module Travis::API::V3
  class Services::Overview::GetBuildTime < Service


    def run!
      repo = find(:repository)
      builds = Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name).where('duration IS NOT NULL').order("id DESC").last(20)
      data = []
      for build in builds do
        data.push ({
          "id" => build.id,
          "state" => build.state,
          "duration" => build.duration
        })
      end
      return [{build_time: data}]
    end
  end
end
