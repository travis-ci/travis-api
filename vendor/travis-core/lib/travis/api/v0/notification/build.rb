module Travis
  module Api
    module V0
      module Notification
        class Build
          attr_reader :build

          def initialize(build, options = {})
            @build = build
          end

          def data
            {
              'build' => build_data
            }
          end

          def build_data
            {
              'id' => build.id
            }
          end
        end
      end
    end
  end
end

