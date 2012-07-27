require 'travis/api/app'

class Travis::Api::App
  class Middleware
    # Makes sure we use Travis.logger everywhere.
    class Logging < Middleware
      set(:setup) { ActiveRecord::Base.logger = Travis.logger }

      before do
        env['rack.logger'] = Travis.logger
        env['rack.errors'] = Travis.logger.instance_variable_get(:@logdev).dev rescue nil
      end
    end
  end
end
