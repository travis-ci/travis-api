module Travis
  module Api
    module V2
      module Http
        class Broadcasts
          attr_reader :broadcasts, :options

          def initialize(broadcasts, options = {})
            @broadcasts = broadcasts
            @options = options
          end

          def data
            {
              'broadcasts' => broadcasts.map { |broadcast| broadcast_data(broadcast) }
            }
          end

          private

            def broadcast_data(broadcast)
              {
                'id' => broadcast.id,
                'message' => broadcast.message
              }
            end
        end
      end
    end
  end
end

