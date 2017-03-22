module Travis
  module Api
    module Serialize
      module V2
        module Http
          class RemoteLog
            attr_reader :log

            def initialize(log, options = {})
              @log = log
            end

            def data
              log.as_json
            end
          end
        end
      end
    end
  end
end
