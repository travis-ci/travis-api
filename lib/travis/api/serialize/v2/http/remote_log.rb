module Travis
  module Api
    module Serialize
      module V2
        module Http
          class RemoteLog
            attr_reader :log, :params
            attr_accessor :serialization_options

            def initialize(log, params = {})
              @log = log
              @params = params
            end

            def data
              log.as_json(chunked: chunked?)
            end

            private

              def chunked?
                !!params.fetch(:chunked, serialization_options[:chunked])
              end
          end
        end
      end
    end
  end
end
