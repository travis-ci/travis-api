module Travis
  module Api
    class App
      class Service
        class Workers < Service
          def collection
            Worker.order(:host, :name)
          end
        end
      end
    end
  end
end

