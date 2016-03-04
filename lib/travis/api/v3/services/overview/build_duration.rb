module Travis::API::V3
  class Services::Overview::BuildDuration < Service

    def run!
      builds = query.build_duration(find(:repository))
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
