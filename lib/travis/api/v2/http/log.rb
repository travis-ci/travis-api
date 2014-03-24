module Travis
  module Api
    module V2
      module Http
        class Log
          attr_reader :log, :options

          def initialize(log, options = {})
            @log = log
            @options = options
          end

          def data
            {
              'log' => options[:chunked] ? chunked_log_data : log_data,
            }
          end

          private

            def log_data
              {
                'id' => log.id,
                'job_id' => log.job_id,
                'type' => log.class.name.demodulize,
                'body' => log.content
              }
            end

            def chunked_log_data
              {
                'id' => log.id,
                'job_id' => log.job_id,
                'type' => log.class.name.demodulize,
                'parts' => log_parts
              }
            end

            def log_parts
              log.parts.sort_by(&:number).map do |part|
                {
                  'id' => part.id,
                  'number' => part.number,
                  'content' => part.content,
                  'final' => part.final
                }
              end
            end
        end
      end
    end
  end
end

