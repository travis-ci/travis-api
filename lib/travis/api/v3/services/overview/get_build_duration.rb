module Travis::API::V3
  class Services::Overview::GetBuildDuration < Service

    def run!
      repo = find(:repository)
      builds = Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name).where("duration IS NOT NULL").where("state != 'canceled'").order("id DESC").last(20)
      data = []
      for build in builds do
        data.push ({
          "id"       => build.id,
          "number"   => build.number,
          "state"    => build.state,
          "duration" => build.duration
        })
      end
      [{build_duration: data}]
    end
  end
end
