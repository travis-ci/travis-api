require 'travis/model/build'
class Build
  module Metrics
    def start(data = {})
      super
      meter 'travis.builds.start.delay', started_at - request.created_at
    end

    private

      def meter(name, time)
        Metriks.timer(name).update(time)
      end
  end
end
