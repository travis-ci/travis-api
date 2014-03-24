module Travis
  module Api
    module V2
      module Http
        class Annotations
          include Formats

          def initialize(annotations, options = {})
            @annotations = annotations
          end

          def data
            {
              "annotations" => @annotations.map { |annotation| build_annotation(annotation) },
            }
          end

          private

          def build_annotation(annotation)
            {
              "id" => annotation.id,
              "job_id" => annotation.job_id,
              "description" => annotation.description,
              "url" => annotation.url,
              "status" => annotation.status,
              "provider_name" => annotation.annotation_provider.name,
            }
          end
        end
      end
    end
  end
end
