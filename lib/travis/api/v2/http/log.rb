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
            log_hash = options[:chunked] ? chunked_log_data : log_data
            if log.removed_at
              log_hash['removed_at'] = log.removed_at
              log_hash['removed_by'] = log.removed_by.name || object.removed_by.login
            end

            {
              'log' => log_hash,
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
              if log.removed_at
                # if log is removed we don't have actual parts
                parts = [{ 'number' => 1, 'content' => log.content, 'final' => true }]
              else
                parts = log.parts
                parts = parts.where(number: part_numbers) if part_numbers
                parts = parts.where(["number > ?", after]) if after
                parts.sort_by(&:number).map do |part|
                  {
                    'id' => part.id,
                    'number' => part.number,
                    'content' => part.content,
                    'final' => part.final
                  }
                end
              end
            end

            def after
              after = options['after'].to_i
              after == 0 ? nil : after
            end

            def part_numbers
              if numbers = options['part_numbers']
                numbers.is_a?(String) ? numbers.split(',').map(&:to_i) : numbers
              end
            end
        end
      end
    end
  end
end

