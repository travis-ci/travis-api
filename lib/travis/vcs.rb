module Travis
  module VCS
    def vcs
      @vcs ||= Faraday.new(url: Travis::Config.load.vcs.endpoint) do |c|
        c.headers['Authorization'] = "Bearer #{Travis::Config.load.vcs.token}"
        c.headers['Content-Type'] = 'application/json'
        c.adapter Faraday.default_adapter
      end
    end
  end
end
