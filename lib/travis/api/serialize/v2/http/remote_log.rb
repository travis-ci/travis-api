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
              log.as_json(
                chunked: chunked?,
                after: params[:after],
                part_numbers: part_numbers
              )
            end

            private

              def chunked?
                !!params.fetch(:chunked, serialization_options[:chunked])
              end

              def part_numbers
                @part_numbers ||= params[:part_numbers].to_s
                                                       .split(',')
                                                       .map(&:to_i)
              end
          end
        end
      end
    end
  end
end
