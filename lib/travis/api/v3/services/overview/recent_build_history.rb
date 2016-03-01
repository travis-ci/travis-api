module Travis::API::V3
  class Services::Overview::RecentBuildHistory < Service

    def run!
      repo = find(:repository)

      builds = Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name).where("created_at > ?", Date.today - 9).group(:state, "date_trunc('day', created_at)").count

      hash = {}
      hash.default_proc = proc do |hash, key|
        hash[key] = Hash.new(0)
      end

      builds.each {|key, value|
        state      = key[0]
        created_at = key[1]
        hash[created_at.to_date][state] = value
      }

      [{recent_build_history: hash}]
    end
  end
end
