module Travis::API::V3
  class Services::Overview::RecentBuildHistory < Service

    def run!
      builds = query.recent_build_history(find(:repository))

      hash = Hash.new { |hash, key| hash[key] = Hash.new(0) }

      builds.each {|key, value|
        created_at = key[0]
        state      = key[1]
        hash[created_at.to_date][state] = value
      }

      [{recent_build_history: hash}]
    end
  end
end
