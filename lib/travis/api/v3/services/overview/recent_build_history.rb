module Travis::API::V3
  class Services::Overview::RecentBuildHistory < Service

    def run!
      repo = find(:repository)
      builds = Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name).where("created_at > ?", Date.today - 9)

      hash = {}
      hash.default_proc = proc do |hash, key|
        hash[key] = Hash.new(0)
      end

      for build in builds do
        hash[build.created_at.to_date][build.state] += 1
      end

      [{recent_build_history: hash}]
    end
  end
end
