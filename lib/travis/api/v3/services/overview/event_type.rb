module Travis::API::V3
  class Services::Overview::EventType < Service

    def run!
      builds = query.event_type(find(:repository))

      hash = {}
      hash.default_proc = proc do |hash, key|
        hash[key] = Hash.new(0)
      end

      builds.each {|key, value|
        event_type = key[0]
        state      = key[1]
        hash[event_type][state] = value
      }

      [{event_type: hash}]
    end
  end
end
