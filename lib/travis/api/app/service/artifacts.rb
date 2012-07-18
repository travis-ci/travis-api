module Travis
  module Api
    class App
      class Service
        class Artifacts < Service
          def element
            Artifact.find(params[:id])
          end
        end
      end
    end
  end
end

