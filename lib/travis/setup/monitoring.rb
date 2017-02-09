module Travis::Setup
  module Monitoring
    extend self

    def setup
      return unless use_monitoring?
      Travis::Metrics.setup
    end

    def use_monitoring?
      Travis.production? and not defined? Travis::Console
    end
  end
end
