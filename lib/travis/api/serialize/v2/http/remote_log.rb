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
              puts "PARM: #{params.inspect}"
              puts "LOG: #{log.inspect}"
              res = log.as_json(
                chunked: chunked?,
                after: params[:after],
                part_numbers: part_numbers
              )
              puts "\n\nLOG1: #{res.inspect}"
              res
            rescue => e
              puts "ERR: #{e.inspect}"
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
