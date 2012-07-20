module Travis
  module Api
    class App
      class Service
        class Artifacts < Service
          def item
            Artifact.find(params[:id])
          end
        end
      end
    end
  end
end

