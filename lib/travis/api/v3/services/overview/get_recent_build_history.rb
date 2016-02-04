module Travis::API::V3
  class Services::Overview::GetRecentBuildHistory < Service

    def run!
      repo = find(:repository)
      builds = Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name).where("started_at > ?", Date.today - 9)

      hash = {}
      hash.default_proc = proc do |hash, key|
        hash[key] = Hash.new(0)
      end

      for build in builds do
        hash[build.started_at.to_date][build.state] += 1
      end

      return [{recent_build_history: hash}]
    end
  end
end
