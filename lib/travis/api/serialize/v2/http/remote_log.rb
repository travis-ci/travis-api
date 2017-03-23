module Travis
  module Api
    module Serialize
      module V2
        module Http
          class RemoteLog
            attr_reader :log, :options

            def initialize(log, options = {})
              @log = log
              @options = options
            end

            def data
              log.as_json(chunked: !!options[:chunked])
            end
          end
        end
      end
    end
  end
end
